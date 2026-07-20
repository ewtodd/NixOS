{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The LibreChat application version (matches nixpkgs `pkgs.librechat`).
  # Upstream publishes a multi-arch image (amd64 + arm64) at:
  #   https://github.com/danny-avila/LibreChat/pkgs/container/librechat
  # Using the upstream image sidesteps the from-source nixpkgs build that,
  # combined with the unfree `mongodb` package (no Hydra binary cache),
  # was OOMing the aarch64 builder for ~90min per attempt on oracle.
  librechatImage = "ghcr.io/danny-avila/librechat:v0.8.6";

  # mongo:7 is multi-arch (amd64 + arm64); replaces the unfree nixpkgs
  # `mongodb` package, which has no binary cache on any platform and must
  # be built from source — the actual cause of the 1.5hr ARM OOM.
  mongoImage = "mongo:7";

  # Generate librechat.yaml in the same format the nixpkgs `services.librechat`
  # module produces, so the existing config carries over verbatim. The only
  # change: `127.0.0.1` -> `host.docker.internal` so the container can reach
  # the host's LiteLLM proxy + MCP gateway via the docker bridge gateway.
  librechatYaml = (pkgs.formats.yaml { }).generate "librechat.yaml" {
    version = "1.2.1";
    interface.webSearch = false;
    mcpSettings.allowedAddresses = [
      "host.docker.internal:4000"
      "127.0.0.1:4000"
      "localhost:4000"
    ];
    endpoints.agents = {
      recursionLimit = 75;
      maxRecursionLimit = 100;
    };
    endpoints.custom = [
      {
        name = "LiteLLM";
        baseURL = "http://host.docker.internal:4000/v1";
        apiKey = "\${LITELLM_API_KEY}";
        modelDisplayLabel = "son of anton";
        models = {
          default = [
            "auto"
            "qwen3.5-122b-a10b"
            "qwen3.6-35b-a3b-general"
            "qwen3.6-27b-general"
            "gemma-4-31b"
            "qwen3.6-27b-heretic-general"
            "gemma-4-31b-heretic"
            "gemma-4-26b-a4b"
            "deepseek-v4-flash-max"
            "deepseek-v4-flash-high"
            "deepseek-v4-flash-no-thinking"
            "fast-gemma-4-12b-it"
            "fast-qwen3.6-27b"
          ];
          fetch = false;
        };
        titleConvo = true;
        titleModel = "qwen3-4b-instruct";
      }
    ];
    mcpServers =
      lib.genAttrs
        [
          "fetch"
          "searxng"
          "nixos"
          "arxiv"
          "context7"
        ]
        (server: {
          type = "streamable-http";
          url = "http://host.docker.internal:4000/mcp/";
          requiresOAuth = false;
          headers = {
            Authorization = "Bearer \${LITELLM_API_KEY}";
            "x-mcp-servers" = server;
          };
        });
  };

  dataDir = "/var/lib/librechat";
  mongoDir = "/var/lib/librechat-mongo";

  # Combined env file written at runtime: the agenix `librechat-env` file
  # (CREDS_KEY, CREDS_IV, JWT_SECRET, JWT_REFRESH_SECRET, LITELLM_API_KEY)
  # plus MEILI_MASTER_KEY read from the separate meilisearch-api-key secret.
  # systemd's EnvironmentFile reads this before invoking `docker run`, so
  # all vars are passed to the container as env vars.
  combinedEnvFile = "/run/librechat-combined-env";
in
{
  config = lib.mkIf config.systemOptions.services.librechat.enable {
    networking.firewall.allowedTCPPorts = [ 3080 ];

    # Docker is required to run the upstream multi-arch images. Trusted
    # docker0 so container -> host (LiteLLM :4000, meilisearch :7700)
    # traffic via the bridge gateway isn't dropped by the host firewall.
    virtualisation.docker.enable = true;
    networking.firewall.trustedInterfaces = [ "docker0" ];

    # Meilisearch stays native — its nixpkgs package is free software and
    # cached on aarch64, so no source build. Bound to 0.0.0.0 so the
    # LibreChat container can reach it via host.docker.internal:7700.
    services.meilisearch = {
      enable = true;
      listenAddress = "0.0.0.0";
      masterKeyFile = config.age.secrets.meilisearch-api-key.path;
    };

    # Declarative librechat.yaml mounted read-only into the container.
    environment.etc."librechat/librechat.yaml".source = librechatYaml;

    # Persistent data directories for the containers.
    systemd.tmpfiles.settings."10-librechat" = {
      "${dataDir}" = {
        d = {
          mode = "0755";
          user = "root";
          group = "root";
        };
      };
      "${dataDir}/logs" = {
        d = {
          mode = "0755";
          user = "root";
          group = "root";
        };
      };
      "${dataDir}/images" = {
        d = {
          mode = "0755";
          user = "root";
          group = "root";
        };
      };
      "${dataDir}/uploads" = {
        d = {
          mode = "0755";
          user = "root";
          group = "root";
        };
      };
      # mongo:7 image runs as uid/gid 999 (mongodb user inside the container).
      "${mongoDir}" = {
        d = {
          mode = "0755";
          user = "999";
          group = "999";
        };
      };
    };

    # Assemble the combined env file at runtime (librechat-env + MEILI_MASTER_KEY).
    # agenix decrypts both secrets to /run/agenix/* at boot; this oneshot reads
    # them and writes a single env file the docker-librechat unit will load.
    systemd.services.librechat-env-assembly = {
      description = "Assemble runtime env file for LibreChat container";
      wantedBy = [ "multi-user.target" ];
      after = [ "agenix.service" ];
      requires = [ "agenix.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        umask 077
        {
          cat ${config.age.secrets.librechat-env.path}
          MEILI_KEY="$(cat ${config.age.secrets.meilisearch-api-key.path})"
          echo "MEILI_MASTER_KEY=$MEILI_KEY"
        } > ${combinedEnvFile}
        chown root:root ${combinedEnvFile}
        chmod 0400 ${combinedEnvFile}
      '';
    };

    # MongoDB container — replaces the unfree nixpkgs mongodb package.
    virtualisation.oci-containers.containers.librechat-mongo = {
      image = mongoImage;
      volumes = [ "${mongoDir}:/data/db" ];
      extraOptions = [ "--restart=unless-stopped" ];
    };

    # LibreChat container — multi-arch upstream image (arm64 included).
    virtualisation.oci-containers.containers.librechat = {
      image = librechatImage;
      ports = [ "3080:3080" ];
      volumes = [
        "/etc/librechat/librechat.yaml:/app/librechat.yaml:ro"
        "${dataDir}/logs:/app/logs"
        "${dataDir}/images:/app/client/public/images"
        "${dataDir}/uploads:/app/uploads"
      ];
      environment = {
        HOST = "0.0.0.0";
        ALLOW_REGISTRATION = "false";
        MONGO_URI = "mongodb://librechat-mongo:27017";
        MEILI_HOST = "http://host.docker.internal:7700";
        SEARCH = "true";
      };
      environmentFiles = [ combinedEnvFile ];
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
        "--depends-on=librechat-mongo"
        "--restart=unless-stopped"
      ];
    };

    # Wait for the env file + mongo before starting librechat, and restart
    # the container if either agenix secret changes.
    systemd.services.docker-librechat = {
      requires = [ "librechat-env-assembly.service" ];
      after = [
        "librechat-env-assembly.service"
        "docker-librechat-mongo.service"
      ];
      restartTriggers = [
        config.age.secrets.librechat-env.file
        config.age.secrets.meilisearch-api-key.file
      ];
    };
  };
}
