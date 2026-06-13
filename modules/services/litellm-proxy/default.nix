{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.litellmProxy.enable {
    networking.firewall.allowedTCPPorts = [ 4000 ]; # nu's Caddy + LAN reach the proxy

    # The container bind-mounts the master-key secret by path, so editing
    # litellm-master-key.age alone leaves container@litellm.service unchanged and
    # activation won't restart it (stale key inside). Trigger on the encrypted
    # file's store path (hash tracks contents) so a deploy recreates it.
    systemd.services."container@litellm".restartTriggers = [
      config.age.secrets.litellm-master-key.file
    ];

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
          # arXiv search/paper-analysis MCP (PyPI, packaged locally). No local
          # data dependency -- it fetches from arxiv.org and caches papers under
          # the litellm StateDirectory.
          arxiv-mcp-server = pkgs.callPackage ./pkgs/arxiv-mcp-server.nix { };
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
                arxiv = {
                  transport = "stdio";
                  command = lib.getExe arxiv-mcp-server;
                  args = [
                    "--storage-path"
                    "/var/lib/litellm/arxiv-papers"
                  ];
                };
                # Up-to-date, version-specific library docs (incl. CERN ROOT,
                # which Context7 indexes as /root-project/root with ~63k
                # snippets). Anonymous/rate-limited; set CONTEXT7_API_KEY (free)
                # here if limits become a problem.
                context7 = {
                  transport = "stdio";
                  command = lib.getExe pkgs.context7-mcp;
                  args = [ ];
                };
              };

              # No cycles: each chain terminates at gpt-oss-120b. (Previously
              # big-moe <-> gpt-oss-120b pointed at each other, so a persistent
              # upstream 400 -- e.g. LibreChat sending an unsupported content
              # part -- bounced between them forever, reloading each giant model
              # on every hop via the llama-swap matrix.)
              router_settings.fallbacks = [
                {
                  "Qwen3-30B-A3B-Instruct-2507 (ultra-fast)" = [ "Qwen3-Coder-Next (smart-coder)" ];
                }
                {
                  "Qwen3-Coder-Next (smart-coder)" = [ "Qwen3.5-122B-A10B (big-moe)" ];
                }
                {
                  "Qwen3.5-122B-A10B (big-moe)" = [ "gpt-oss-120b" ];
                }
                {
                  auto = [ "Qwen3.5-122B-A10B (big-moe)" ];
                }
              ];

              model_list = [
                {
                  model_name = "Qwen3-Coder-Next (smart-coder)"; # coding (any complexity)
                  litellm_params = {
                    model = "openai/qwen3-coder-next";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "Qwen3-30B-A3B-Instruct-2507 (ultra-fast)"; # general + simple
                  litellm_params = {
                    model = "openai/qwen3-30b-a3b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "Qwen3.5-122B-A10B (big-moe)"; # general + complex / orchestrator default
                  litellm_params = {
                    model = "openai/qwen3.5-122b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  # Name-selectable only; intentionally absent from the `auto`
                  # classifier and the fallback chains (like gpt-oss-120b).
                  model_name = "Qwen3.6-35B-A3B (experiment)";
                  litellm_params = {
                    model = "openai/qwen3.6-35b-a3b";
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
                {
                  # Title-generation alias for LibreChat: same loaded 122b server
                  # (no model swap), but the classifier hook forces
                  # enable_thinking=false on this model name so titles return in
                  # ~1s instead of the model spending 20s+ reasoning and tripping
                  # LibreChat's title timeout. See services.librechat titleModel.
                  model_name = "Qwen3.5-122B-A10B (titles)";
                  litellm_params = {
                    model = "openai/qwen3.5-122b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  # Embeddings for the RAG API (LibreChat file search). Served by
                  # the bge-m3 llama-server behind llama-swap; rag_api calls
                  # /v1/embeddings here with model "bge-m3".
                  model_name = "bge-m3";
                  litellm_params = {
                    model = "openai/bge-m3";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                  model_info.mode = "embedding";
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
            "mcp-server-fetch,mcp-nixos,arxiv-mcp-server,context7-mcp";

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
