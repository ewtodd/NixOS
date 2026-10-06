{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  buildPkgs =
    if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then
      import pkgs.path {
        localSystem.system = "x86_64-linux";
        crossSystem.system = "aarch64-linux";
      }
    else
      pkgs;

  bifrostVersion = lib.strings.trim (builtins.readFile "${inputs.bifrost}/transports/version");

  bifrost-ui =
    (buildPkgs.buildPackages.callPackage "${inputs.bifrost}/nix/packages/bifrost-ui.nix" {
      src = inputs.bifrost;
      version = bifrostVersion;
    }).overrideAttrs
      (_: {
        npmDeps = buildPkgs.buildPackages.fetchNpmDeps {
          name = "bifrost-ui-${bifrostVersion}-npm-deps";
          src = inputs.bifrost;
          sourceRoot = "source/ui";
          hash = "sha256-lXyg2jRD+KyLv/3kM2xiT72jlviiFFNq9t/NOThk0rs=";
        };
      });

  bifrost-http = buildPkgs.callPackage ./pkgs/bifrost-http.nix {
    src = inputs.bifrost;
    version = bifrostVersion;
    inherit bifrost-ui;
  };

  sonOfAntonVllm = "http://10.0.0.5:8100"; # vLLM on R9700s (TP=2)
  sonOfAntonStrix = "http://10.0.0.5:8050"; # llama.cpp strix-halo, Qwen3.8-Flash-Next on the iGPU
  oracleSwap = "http://10.0.0.6:8080"; # llama-swap on this host

  streamIdleTimeout = 300;

  # The friend key answers only during ricky's active hours
  # (hosts/e-desktop, gateway.active_hours = [ 20 7 ]): 20:00-07:00
  # America/Chicago, wrapping midnight. A timer keeps the key's is_active in
  # step with the clock; the key's description is what the refusal says.
  friendActiveHours = {
    start = 20;
    end = 7;
    timezone = "America/Chicago";
  };

  friendKeyToggle = pkgs.writeShellScript "bifrost-friend-key-toggle" ''
    set -eu
    hour=$(TZ=${friendActiveHours.timezone} ${lib.getExe' pkgs.coreutils "date"} +%-H)
    if [ "$hour" -ge ${toString friendActiveHours.start} ] || [ "$hour" -lt ${toString friendActiveHours.end} ]; then
      is_active=true
    else
      is_active=false
    fi
    exec ${lib.getExe pkgs.curl} \
      --fail --silent --show-error \
      --user "$BIFROST_ADMIN_USERNAME:$BIFROST_ADMIN_PASSWORD" \
      --request PUT \
      --header "Content-Type: application/json" \
      --data "{\"is_active\":$is_active}" \
      http://127.0.0.1:4002/api/governance/virtual-keys/friend
  '';

  arxiv-mcp-server = pkgs.callPackage ./pkgs/arxiv-mcp-server.nix {
    src = inputs.arxiv-mcp-server-src;
  };

  # Owner and friend instances of the same gateway; the friend key is scoped to
  # the 27B by provider allowlist, rate-limited, and off outside ricky's hours.
  mcpClients = [
    "fetch"
    "searxng"
    "nixos"
    "arxiv"
    "context7"
  ];
in
{
  imports = [ "${inputs.bifrost}/nix/modules/bifrost.nix" ];

  config = lib.mkIf config.systemOptions.services.bifrost.enable {
    services.bifrost = {
      enable = true;
      package = bifrost-http;
      host = "0.0.0.0";
      port = 4002;
      stateDir = "/var/lib/bifrost";
      logLevel = "info";
      logStyle = "json";
      openFirewall = true;

      # mcp-searxng reads this (forwarded via the stdio `envs` list below) and
      # queries the host-local SearXNG instance.
      environment.SEARXNG_URL = "http://127.0.0.1:8888";

      # Every consumer has its own virtual key (bifrost-keys); admin auth,
      # the encryption key and the DeepSeek key live in bifrost-env.
      environmentFile = config.age.secrets.bifrost-env.path;

      settings = {
        # config.json is the source of truth, so removing a provider here (as
        # with the first vllm attempt) prunes it from the SQLite store instead
        # of leaving a stale row behind.
        source_of_truth = "config.json";

        client = {
          enforce_auth_on_inference = true;
          # son-of-anton and opencode fetch MCP tools themselves; do not also
          # attach them to every inference request.
          mcp_disable_auto_tool_inject = true;
        };

        providers = {
          # First-class vLLM provider: the server URL lives on the key
          # (vllm_key_config.url), not in network_config.
          vllm = {
            network_config = {
              allow_private_network = true;
              default_request_timeout_in_seconds = 1800;
              stream_idle_timeout_in_seconds = streamIdleTimeout;
            };
            keys = [
              {
                name = "qwen38-27b";
                value = "";
                models = [ "qwen3.8-27b" ];
                weight = 1.0;
                vllm_key_config.url = sonOfAntonVllm;
              }
            ];
          };

          strix = {
            custom_provider_config = {
              base_provider_type = "openai";
              is_key_less = true;
            };
            network_config = {
              base_url = sonOfAntonStrix;
              allow_private_network = true;
              default_request_timeout_in_seconds = 1800;
              stream_idle_timeout_in_seconds = streamIdleTimeout;
            };
            keys = [
              {
                name = "qwen38-flash-next";
                value = "";
                models = [ "qwen3.8-flash-next" ];
                weight = 1.0;
              }
            ];
          };

          oracle = {
            custom_provider_config = {
              base_provider_type = "openai";
              is_key_less = true;
            };
            network_config = {
              base_url = oracleSwap;
              allow_private_network = true;
              default_request_timeout_in_seconds = 1800;
              stream_idle_timeout_in_seconds = streamIdleTimeout;
            };
            keys = [
              {
                name = "little-titles";
                value = "";
                models = [ "little-titles" ];
                weight = 1.0;
              }
            ];
          };

          # bge-m3 embeddings for RAG. The llama.cpp embedding server binds
          # 127.0.0.1:8082 on oracle (see llamaSwap.embeddingModel), so it is
          # reachable only from Bifrost on this host; clients use the normal
          # virtual-key route with model "bge-m3".
          embed = {
            custom_provider_config = {
              base_provider_type = "openai";
              is_key_less = true;
            };
            network_config = {
              base_url = "http://127.0.0.1:8082";
              allow_private_network = true;
              default_request_timeout_in_seconds = 120;
            };
            keys = [
              {
                name = "bge-m3";
                value = "";
                models = [ "bge-m3" ];
                weight = 1.0;
              }
            ];
          };

          deepseek = {
            keys = [
              {
                name = "deepseek-v4-api";
                value = "env.DEEPSEEK_API_KEY";
                models = [ "deepseek-v4-flash" ];
                weight = 1.0;
                aliases."deepseek-v4-api" = "deepseek-flash";
              }
            ];
          };
        };

        mcp.client_configs = [
          {
            name = "fetch";
            connection_type = "stdio";
            stdio_config = {
              command = lib.getExe pkgs.mcp-server-fetch;
              args = [ ];
            };
            auth_type = "none";
            tools_to_execute = [ "*" ];
          }
          {
            name = "searxng";
            connection_type = "stdio";
            stdio_config = {
              command = lib.getExe pkgs.mcp-searxng;
              args = [ ];
              envs = [ "SEARXNG_URL" ];
            };
            auth_type = "none";
            tools_to_execute = [ "*" ];
          }
          {
            name = "nixos";
            connection_type = "stdio";
            stdio_config = {
              command = lib.getExe pkgs.mcp-nixos;
              args = [ ];
            };
            auth_type = "none";
            tools_to_execute = [ "*" ];
          }
          {
            name = "arxiv";
            connection_type = "stdio";
            stdio_config = {
              command = lib.getExe arxiv-mcp-server;
              args = [
                "--storage-path"
                "/var/lib/bifrost/arxiv-papers"
              ];
            };
            auth_type = "none";
            tools_to_execute = [ "*" ];
          }
          {
            name = "context7";
            connection_type = "stdio";
            stdio_config = {
              command = lib.getExe pkgs.context7-mcp;
              args = [ ];
            };
            auth_type = "none";
            tools_to_execute = [ "*" ];
          }
        ];

        governance = {
          auth_config = {
            is_enabled = true;
            admin_username = "env.BIFROST_ADMIN_USERNAME";
            admin_password = "env.BIFROST_ADMIN_PASSWORD";
          };

          routing_rules = [ ];

          virtual_keys = [
            {
              id = "opencode";
              name = "opencode";
              value = "env.BIFROST_OPENCODE_VK";
              allow_all_providers = true;
              # opencode talks to the gateway's /mcp/searxng endpoint; the
              # grant narrows what that key can reach.
              mcp_configs = [
                {
                  mcp_client_name = "searxng";
                  tools_to_execute = [ "*" ];
                }
              ];
            }
            {
              id = "open-webui";
              name = "open-webui";
              value = "env.BIFROST_OPENWEBUI_VK";
              allow_all_providers = true;
            }
            {
              id = "soa";
              name = "son-of-anton";
              value = "env.BIFROST_SOA_VK";
              allow_all_providers = true;
              mcp_configs = map (name: {
                mcp_client_name = name;
                tools_to_execute = [ "*" ];
              }) mcpClients;
            }
            {
              id = "friend";
              name = "friend";
              value = "env.BIFROST_FRIEND_VK";
              # Ships off and is switched on by the timer below, so a dead
              # timer fails closed. The description is surfaced verbatim as
              # the 403; see the patched governance refusal.
              description = "The friend key is only active 20:00-07:00 America/Chicago (8pm-7am).";
              is_active = false;
              rate_limit_id = "friend-rpm";
              provider_configs = [
                {
                  provider = "vllm";
                  allowed_models = [ "qwen3.8-27b" ];
                  key_ids = [ "*" ];
                }
              ];
            }
          ];

          rate_limits = [
            {
              id = "friend-rpm";
              request_max_limit = 30;
              request_reset_duration = "1m";
            }
          ];
        };
      };
    };

    systemd.services.bifrost.serviceConfig.EnvironmentFile = lib.mkAfter [
      config.age.secrets.bifrost-keys.path
    ];

    # Bifrost has no time-of-day gating, so the friend window is enforced from
    # outside. The key ships inactive (config.json is the source of truth), so
    # a dead timer fails closed; the timer turns it on inside the window and
    # re-asserts periodically because every Bifrost start resets it off.
    systemd.services.bifrost-friend-key = {
      description = "Set the Bifrost friend virtual key to match ricky's active hours";
      after = [ "bifrost.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = friendKeyToggle;
        EnvironmentFile = [ config.age.secrets.bifrost-env.path ];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };

    systemd.timers.bifrost-friend-key = {
      description = "Timer for the Bifrost friend active-hours toggle";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # Exact boundaries in the same zone the script computes in; the
        # periodic elapse is the repair path for a mid-window service start.
        OnCalendar = [
          "*-*-* ${toString friendActiveHours.start}:00:00 ${friendActiveHours.timezone}"
          "*-*-* ${toString friendActiveHours.end}:00:00 ${friendActiveHours.timezone}"
        ];
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
        Unit = "bifrost-friend-key.service";
      };
    };
  };
}
