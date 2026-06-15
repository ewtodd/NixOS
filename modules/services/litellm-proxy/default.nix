{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.litellmProxy.enable {
    # 4000: nu's Caddy + LAN reach the proxy. 9192: the in-process metrics
    # exporter (litellm_metrics.py callback), scraped by nu's Prometheus.
    networking.firewall.allowedTCPPorts = [
      4000
      9192
    ];

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

              # Callbacks (module.attr, importable from /etc/litellm):
              #  - litellm_metrics.metrics: in-process Prometheus exporter (runs a
              #    /metrics server on :9192, fed from success/failure callbacks).
              #  - auto_router.auto_router: pre-call hook that rewrites model
              #    "auto" to a concrete model via the resident Qwen3-0.6B
              #    classifier (see auto_router.py).
              litellm_settings.callbacks = [
                "litellm_metrics.metrics"
                "auto_router.auto_router"
              ];

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

              # No fallbacks: cross-model fallback caused model-swap loops, and
              # self-fallback only masked the upstream llama.cpp error behind
              # LiteLLM's generic post-retry one. Let calls error so the real
              # failure is visible.

              model_list = [
                {
                  # Classifier-routed alias. The auto_router pre-call hook
                  # rewrites "auto" to a concrete model (code/reasoning/simple/
                  # general via the Qwen3-0.6B classifier, or a vision model when
                  # an image is attached) before routing. This litellm_params
                  # target is just a placeholder to pass model validation — the
                  # hook overrides it on every request.
                  model_name = "auto";
                  litellm_params = {
                    model = "openai/qwen3.6-35b-a3b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
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
                  model_name = "Qwen3.5-122B-A10B (big-moe)"; # general + complex
                  litellm_params = {
                    model = "openai/qwen3.5-122b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  # Default model (LibreChat + qwen-code select this first).
                  model_name = "Qwen3.6-35B-A3B (default)";
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
                  model_name = "NVIDIA-Nemotron-3-Super-120B-A12B"; # general + complex
                  litellm_params = {
                    model = "openai/nemotron-3-super-120b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "Mistral-Small-4-119B (vision)"; # multimodal
                  litellm_params = {
                    model = "openai/mistral-small-4-119b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "Mistral-Medium-3.5-128B (vision)"; # multimodal
                  litellm_params = {
                    model = "openai/mistral-medium-3.5-128b";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "Step-3.7-Flash (vision)"; # multimodal
                  litellm_params = {
                    model = "openai/step-3.7-flash";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "MiniMax-M2.7 (uncensored)"; # experimental, very large
                  litellm_params = {
                    model = "openai/minimax-m2.7";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  # Title-generation alias for LibreChat. Points at the tiny,
                  # alwaysResident Qwen3-0.6B title server — ~0.6GB, ANDed into
                  # every llama-swap matrix set so it rides alongside whatever
                  # chat/coder model is loaded (including the solo ones) without
                  # ever evicting it. Reasoning is forced off server-side (titles
                  # return in ~1s). A *separate* model_name keeps titling out of
                  # any routing/fallback logic. See services.librechat titleModel.
                  model_name = "Qwen3-0.6B (titles)";
                  litellm_params = {
                    model = "openai/qwen3-0.6b";
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
          environment.etc."litellm/searxng_mcp.py".source = ./searxng_mcp.py;
          environment.etc."litellm/litellm_metrics.py".source = ./litellm_metrics.py;
          environment.etc."litellm/auto_router.py".source = ./auto_router.py;

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
