{
  config,
  lib,
  inputs,
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

      # The container shares the host net namespace (no privateNetwork) but has
      # its own /etc/resolv.conf, which the container's resolvconf emits with NO
      # nameserver lines (it has no DHCP/static source of its own). That kills
      # DNS for every name-based MCP server (arxiv, fetch, context7, nixos);
      # searxng only survives because it dials the literal 127.0.0.1:8888.
      # Bind-mount the host's working resolver in so names resolve.
      bindMounts."/etc/resolv.conf" = {
        hostPath = "/etc/resolv.conf";
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
          searxngMcpPython = pkgs.python3.withPackages (ps: [
            ps.mcp
            ps.httpx
          ]);
          arxiv-mcp-server = pkgs.callPackage ./pkgs/arxiv-mcp-server.nix {
            src = inputs.arxiv-mcp-server-src;
          };
          nativeOpenaiParams = [
            "reasoning_effort"
            "thinking"
            "enable_thinking"
            "chat_template_kwargs"
            "min_p"
            "top_k"
            "repeat_penalty"
            "presence_penalty"
            "frequency_penalty"
            "response_format"
          ];
          mkLocal = model: {
            inherit model;
            api_base = "http://127.0.0.1:8080/v1";
            api_key = "none";
            allowed_openai_params = nativeOpenaiParams;
            timeout = 1800;
          };
          # unsloth's recommended sampling for the Qwen3.6 *thinking* models,
          # exposed as distinct model_names so either profile is selectable from
          # a client dropdown (LibreChat's addParams is endpoint-wide, not
          # per-model, so per-profile entries are the only way to choose). Baked
          # into litellm_params as request defaults; top_k/min_p ride through via
          # allowed_openai_params. Per unsloth, BOTH thinking profiles use
          # presence_penalty=0.0 — the 1.5 value is for *instruct/non-thinking*
          # mode only (it fights the repetition loops that plague non-thinking
          # mode; in a thinking/agent loop it instead destabilizes tool-call
          # formatting). So temperature (1.0 general / 0.6 coding) is the only
          # lever between these two profiles; every other key is identical.
          sampling = {
            general = {
              temperature = 1.0;
              top_p = 0.95;
              top_k = 20;
              min_p = 0;
              presence_penalty = 0;
            };
            coding = {
              temperature = 0.6;
              top_p = 0.95;
              top_k = 20;
              min_p = 0;
              presence_penalty = 0;
            };
          };
          mkLocalSampled = model: profile: (mkLocal model) // profile;
        in
        {
          services.litellm = {
            enable = true;
            host = "0.0.0.0";
            port = 4000;
            environmentFile = "/run/agenix/litellm-master-key";

            settings = {
              general_settings.master_key = "os.environ/LITELLM_MASTER_KEY";

              litellm_settings.callbacks = [
                "litellm_metrics.metrics"
                "auto_router.auto_router"
              ];

              litellm_settings.drop_params = false;
              litellm_settings.request_timeout = 1800;

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

              model_list = [
                {
                  model_name = "auto";
                  litellm_params = mkLocal "openai/qwen3.6-35b-a3b-udq8";
                }
                {
                  model_name = "Qwen3-30B-A3B-Instruct-2507 (ultra-fast)";
                  litellm_params = mkLocal "openai/qwen3-30b-a3b";
                }
                {
                  model_name = "Qwen3.5-122B-A10B (large moe)";
                  litellm_params = mkLocal "openai/qwen3.5-122b";
                }
                {
                  model_name = "Qwen3.6-35B-A3B (moe general)";
                  litellm_params = mkLocalSampled "openai/qwen3.6-35b-a3b-udq8" sampling.general;
                }
                {
                  model_name = "Qwen3.6-35B-A3B (moe coding)";
                  litellm_params = mkLocalSampled "openai/qwen3.6-35b-a3b-udq8" sampling.coding;
                }
                {
                  # pi's agentic coding default — it must emit well-formed tool
                  # calls turn after turn. Bare mkLocal would inherit this model's
                  # hot llama-server defaults (thinking-general temp 1.0); give it
                  # unsloth's thinking-*coding* profile (temp 0.6) so the tool-call
                  # scaffold is sampled near-greedily and stops leaking as
                  # half-formed <tool_call> text. (presence_penalty is 0 in both
                  # thinking profiles; see the sampling note above.)
                  model_name = "Qwen3.6-27B (dense coding)";
                  litellm_params = mkLocalSampled "openai/qwen3.6-27b" sampling.coding;
                }
                {
                  model_name = "Gemma-4-31B (dense)";
                  litellm_params = mkLocal "openai/gemma-4-31b";
                }
                {
                  model_name = "Gemma-4-26B-A4B (fast-moe)";
                  litellm_params = mkLocal "openai/gemma-4-26b-a4b";
                }
                {
                  model_name = "gpt-oss-120b";
                  litellm_params = mkLocal "openai/gpt-oss-120b";
                }
                {
                  model_name = "NVIDIA-Nemotron-3-Super-120B-A12B";
                  litellm_params = mkLocal "openai/nemotron-3-super-120b";
                }
                {
                  model_name = "Mistral-Small-4-119B (vision)";
                  litellm_params = mkLocal "openai/mistral-small-4-119b";
                }
                {
                  model_name = "Mistral-Medium-3.5-128B (vision)";
                  litellm_params = mkLocal "openai/mistral-medium-3.5-128b";
                }
                {
                  model_name = "Step-3.7-Flash (vision)";
                  litellm_params = mkLocal "openai/step-3.7-flash";
                }
                {
                  model_name = "MiniMax-M2.7 (uncensored)";
                  litellm_params = mkLocal "openai/minimax-m2.7";
                }
                {
                  model_name = "Qwen3-4B-Instruct (titles)";
                  litellm_params = {
                    model = "openai/qwen3-4b-titles";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "bge-m3";
                  litellm_params = {
                    model = "openai/bge-m3";
                    api_base = "http://127.0.0.1:8080/v1";
                    api_key = "none";
                  };
                  model_info.mode = "embedding";
                }
              ];

              # TODO(multi-user tier): add general_settings.database_url + virtual keys.
            };
          };

          environment.etc."litellm/config.yaml".source =
            (pkgs.formats.yaml { }).generate "litellm-config.yaml"
              config.services.litellm.settings;
          environment.etc."litellm/searxng_mcp.py".source = ./searxng_mcp.py;
          environment.etc."litellm/litellm_metrics.py".source = ./litellm_metrics.py;
          environment.etc."litellm/auto_router.py".source = ./auto_router.py;
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
