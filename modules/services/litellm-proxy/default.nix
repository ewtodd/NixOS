{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.litellmProxy.enable {
    networking.firewall.allowedTCPPorts = [ 4000 ]; # nu's Caddy + LAN reach the proxy

    containers.litellm = {
      autoStart = true;

      bindMounts."/run/agenix/litellm-master-key" = {
        hostPath = "/run/agenix/litellm-master-key";
        isReadOnly = true;
      };

      config =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          # Python interpreter for the bundled SearXNG MCP server (a stdio child
          # of the proxy). `mcp` = the MCP SDK (FastMCP), `httpx` = HTTP client.
          searxngMcpPython = pkgs.python3.withPackages (ps: [
            ps.mcp
            ps.httpx
          ]);
        in
        {
          services.litellm = {
            enable = true;
            host = "0.0.0.0";
            port = 4000;
            environmentFile = "/run/agenix/litellm-master-key";

            settings = {
              general_settings.master_key = "os.environ/LITELLM_MASTER_KEY";

              litellm_settings.callbacks = [ "classifier.router" ];

              mcp_servers = {
                fetch = {
                  transport = "stdio";
                  command = lib.getExe pkgs.mcp-server-fetch;
                  args = [ ];
                };
                searxng = {
                  transport = "stdio";
                  command = "${searxngMcpPython}/bin/python";
                  args = [ "/etc/litellm/searxng_mcp.py" ];
                  env.SEARXNG_URL = "http://127.0.0.1:8888";
                };
                nixos = {
                  transport = "stdio";
                  command = lib.getExe pkgs.mcp-nixos;
                  args = [ ];
                };
              };

              router_settings.fallbacks = [
                {
                  smart-coder = [ "big-moe" ];
                }
                {
                  ultra-fast = [ "smart-coder" ];
                }
                {
                  big-moe = [ "gpt-oss-120b" ];
                }
                {
                  gpt-oss-120b = [ "big-moe" ];
                }
                {
                  auto = [ "big-moe" ];
                }
              ];

              model_list = [
                {
                  model_name = "smart-coder"; # coding (any complexity)
                  litellm_params = {
                    model = "openai/qwen3-coder-next";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "ultra-fast"; # general + simple
                  litellm_params = {
                    model = "openai/qwen3-30b-a3b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "big-moe"; # general + complex / orchestrator default
                  litellm_params = {
                    model = "openai/qwen3.5-122b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "gpt-oss-120b";
                  litellm_params = {
                    model = "openai/gpt-oss-120b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  # Routed entry point. The async_pre_call_hook rewrites this to one
                  # of the three tiers before dispatch; the big-moe mapping here is
                  # only a safe default if the hook is ever bypassed.
                  model_name = "auto";
                  litellm_params = {
                    model = "openai/qwen3.5-122b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
              ];

              # TODO(multi-user tier): add general_settings.database_url (Postgres)
              # + virtual keys here when this stops being single-user.
            };
          };

          environment.etc."litellm/config.yaml".source =
            (pkgs.formats.yaml { }).generate "litellm-config.yaml"
              config.services.litellm.settings;
          environment.etc."litellm/classifier.py".source = ./classifier.py;
          environment.etc."litellm/searxng_mcp.py".source = ./searxng_mcp.py;

          # LiteLLM allowlists stdio MCP commands by basename (default:
          # python/node/npx/uvx/...). fetch and nixos use their own binaries, so
          # whitelist those basenames (comma-separated). searxng runs as
          # `python` and is already allowed.
          systemd.services.litellm.environment.LITELLM_MCP_STDIO_EXTRA_COMMANDS =
            "mcp-server-fetch,mcp-nixos";

          systemd.services.litellm.serviceConfig.ExecStart = lib.mkForce (
            lib.concatStringsSep " " [
              (lib.getExe config.services.litellm.package)
              "--host ${config.services.litellm.host}"
              "--port ${toString config.services.litellm.port}"
              "--config /etc/litellm/config.yaml"
            ]
          );

          system.stateVersion = "25.11";
        };
    };
  };
}
