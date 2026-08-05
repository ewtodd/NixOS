# Open WebUI — self-hosted LLM web interface, served at ai.ethanwtodd.com.
# Public traffic terminates at Caddy on server-nu, passes Anubis proof-of-work,
# and lands here on oracle (:8081; 8080 is already llama-swap). Models are
# OpenAI-compatible llama-swap endpoints on son-of-anton (10.0.0.5) and
# anton (10.0.0.3).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.openWebUI;
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
        ExecStart = "${pkgs.open-webui}/bin/open-webui serve --host 0.0.0.0 --port ${toString cfg.port}";
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
          # Default connection seeded on first run: deepseek-v4-flash via
          # llama-swap on son-of-anton. llama-swap does not validate keys.
          "OPENAI_API_BASE_URL=http://10.0.0.5:8080/v1"
          "OPENAI_API_KEY=llama-swap"
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
