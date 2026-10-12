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
          hash = "sha256-sH7vaaCBRLSwDUNj/C1mwQtaQ+1Ft8AJkILHnugkceQ=";
        };
      });

  bifrost-http = buildPkgs.callPackage ./pkgs/bifrost-http.nix {
    src = inputs.bifrost;
    version = bifrostVersion;
    inherit bifrost-ui;
  };

  sonOfAntonUnholy = "http://10.0.0.5:8200"; # unholy: DeepSeek-V4-Flash on both R9700s + the iGPU
  oracleSwap = "http://10.0.0.6:8080"; # llama-swap on this host

  streamIdleTimeout = 300;
  # unholy prefills a cold 1M-token prompt in ~20 min before its first token, so its requests and
  # streams get an hour (a prompt that repeats an earlier prefix starts in seconds).
  unholyTimeout = 3600;

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
  # dsv4-flash by provider allowlist, rate-limited, and off outside ricky's hours.
  #
  # son-of-anton's MCP grant: client -> allowed (unprefixed) tool names. Every
  # granted schema rides every inference request, so this is kept narrow.
  # fetch and searxng are left out: son-of-anton's core web_search/web_extract
  # already front the same SearXNG instance. arxiv keeps its reading/search
  # tools; the watch/alert/export/reindex surface is rarely worth its schema.
  soaMcpTools = {
    nixos = [ "*" ];
    context7 = [ "*" ];
    arxiv = [
      "search_papers"
      "semantic_search"
      "search_paper_text" # physics.mcp.roles.manager
      "get_abstract"
      "get_paper_outline"
      "read_paper"
      "read_paper_section"
      "download_paper"
    ];
  };
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
          # unholy's OpenAI-compatible server (vLLM's request conventions for DSV4: tools,
          # reasoning_effort none/low/high/max, reasoning + reasoning_content).
          unholy = {
            custom_provider_config = {
              base_provider_type = "openai";
              is_key_less = true;
            };
            network_config = {
              base_url = sonOfAntonUnholy;
              allow_private_network = true;
              default_request_timeout_in_seconds = unholyTimeout;
              stream_idle_timeout_in_seconds = unholyTimeout;
            };
            keys = [
              {
                name = "dsv4-flash";
                value = "";
                models = [ "dsv4-flash" ];
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
                models = [ "deepseek-flash" ];
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
              mcp_configs = lib.mapAttrsToList (name: tools: {
                mcp_client_name = name;
                tools_to_execute = tools;
              }) soaMcpTools;
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
                  provider = "unholy";
                  allowed_models = [ "dsv4-flash" ];
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
