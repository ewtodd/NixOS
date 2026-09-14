# Open WebUI at ai.ethanwtodd.com: Caddy on nu -> Anubis PoW -> oracle :8081 (8080 is llama-swap).
# Models from litellm on this host (127.0.0.1:4000), the same router opencode and son-of-anton use.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.openWebUI;
  # Sources the agenix litellm-master-key secret and re-exports it as OPENAI_API_KEYS (what Open WebUI's
  # OpenAI connection seeds from) -- key stays out of the nix store. Secret must be group-readable (see secrets).
  openWebUIWrapped = pkgs.writeShellScriptBin "open-webui" ''
    if [ -r /run/agenix/litellm-master-key ]; then
      set -a
      . /run/agenix/litellm-master-key
      set +a
      export OPENAI_API_KEYS="$LITELLM_MASTER_KEY"
    fi
    exec ${lib.getExe pkgs.open-webui} "$@"
  '';
in
{
  options.systemOptions.services.openWebUI = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "HTTP port; 8080 is already taken by llama-swap on oracle.";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/open-webui";
      description = "State directory: SQLite DB, uploads, vector DB, secret key.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.open-webui = {
      isSystemUser = true;
      group = "open-webui";
      description = "Open WebUI service";
      home = cfg.dataDir;
    };
    users.groups.open-webui = { };

    systemd.services.open-webui = {
      description = "Open WebUI web interface";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        User = "open-webui";
        Group = "open-webui";
        # The secret key file (.webui_secret_key) is created in the working
        # directory on first start, so this must stay inside the state dir.
        WorkingDirectory = cfg.dataDir;
        StateDirectory = "open-webui";
        StateDirectoryMode = "0700";
        ExecStart = "${openWebUIWrapped}/bin/open-webui serve --host 0.0.0.0 --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = "5s";

        # ENABLE_SIGNUP=false is safe from first boot: Open WebUI only gates
        # signup once the user table is non-empty, so the first visitor can
        # still create the admin account (and signup then self-disables).
        Environment = [
          "DATA_DIR=${cfg.dataDir}"
          "WEBUI_URL=https://ai.ethanwtodd.com"
          "ENABLE_SIGNUP=false"
          "WEBUI_AUTH_COOKIE_SECURE=true"
          # OpenAI connection: litellm on this host, key injected by the wrapper. TASK_MODEL_EXTERNAL routes
          # session-title generation to the always-resident little-titles model (via litellm).
          # Caveat: connections/task model seed into the DB on first run only (Config.seed_defaults skips existing
          # keys) -- on an initialized install the admin sets them in Settings > Connections / Tasks.
          "OPENAI_API_BASE_URL=http://127.0.0.1:4000/v1"
          "TASK_MODEL_EXTERNAL=little-titles-json"
          # RAG embeddings via the dedicated embedding server on this host (:8082, bge-m3 on CPU).
          # RAG_OPENAI_API_BASE_URL must be set explicitly: it defaults to the litellm chat endpoint, failing every call.
          "RAG_EMBEDDING_ENGINE=openai"
          "RAG_EMBEDDING_MODEL=bge-m3"
          "RAG_OPENAI_API_BASE_URL=http://127.0.0.1:8082/v1"
          "RAG_OPENAI_API_KEY=llama-swap"
          # Built-in web search backed by the SearXNG instance on this host
          # (modules/services/searxng binds 127.0.0.1:8888). The provider appends
          # q= and format=json itself, so only the bare endpoint is needed.
          "ENABLE_WEB_SEARCH=true"
          "WEB_SEARCH_ENGINE=searxng"
          "SEARXNG_QUERY_URL=http://127.0.0.1:8888/search"
        ];

        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
