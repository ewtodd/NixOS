# Open WebUI — self-hosted LLM web interface, served at ai.ethanwtodd.com.
# Public traffic terminates at Caddy on nu, passes Anubis proof-of-work,
# and lands here on oracle (:8081; 8080 is already llama-swap). Models come
# from litellm on this host (127.0.0.1:4000), the same router opencode and
# the son-of-anton gateway use: llama-swap on son-of-anton (10.0.0.5),
# oracle's always-resident supra-title, and the hosted DeepSeek models.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.openWebUI;
  # The litellm master key lives in an agenix secret as LITELLM_MASTER_KEY=
  # KEY=VALUE lines. Sourcing it and re-exporting as OPENAI_API_KEYS (the
  # env Open WebUI's OpenAI connection seeds from) keeps the key out of the
  # nix store — same pattern as the opencode wrapper. Requires the secret
  # to be group-readable by open-webui (see modules/secrets/default.nix).
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
          # OpenAI connection: litellm on this host, key injected by the
          # wrapper above. TASK_MODEL_EXTERNAL routes session-title
          # generation to the tiny always-resident supra-title model (via
          # litellm → oracle's llama-swap) instead of the chat's own model.
          # Caveat: connections and the task model are seeded into the DB
          # from these env vars on first run only (Config.seed_defaults
          # skips existing keys), so on an already-initialized install the
          # admin sets them once in Settings > Connections / Settings >
          # Tasks.
          "OPENAI_API_BASE_URL=http://127.0.0.1:4000/v1"
          "TASK_MODEL_EXTERNAL=supra-title"
          # RAG embeddings via the dedicated llama.cpp embedding server on
          # this host (bge-m3 on CPU, modules/services/llama-swap
          # embeddingModel). RAG_OPENAI_API_BASE_URL must be set explicitly —
          # it defaults to OPENAI_API_BASE_URL (the litellm chat endpoint),
          # which would fail every embedding call.
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
