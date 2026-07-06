{
  config,
  lib,
  inputs,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.litellmProxy.enable {
    networking.firewall.allowedTCPPorts = [
      4000
      9192
    ];

    systemd.services."container@litellm".restartTriggers = [
      config.age.secrets.litellm-master-key.file
    ];

    containers.litellm = {
      autoStart = true;

      bindMounts."/run/agenix/litellm-master-key" = {
        hostPath = "/run/agenix/litellm-master-key";
        isReadOnly = true;
      };

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
            gemmaTool = {
              temperature = 0.7;
              top_p = 0.95;
              top_k = 20;
              min_p = 0;
              repeat_penalty = 1.08;
              frequency_penalty = 0.1;
              presence_penalty = 0;
            };
            gptOssTool = {
              temperature = 0.7;
              top_p = 0.95;
              top_k = 20;
              min_p = 0;
              repeat_penalty = 1.12;
              frequency_penalty = 0.1;
              presence_penalty = 0;
            };
            qwenLargeMoeTool = {
              temperature = 0.5;
              top_p = 0.95;
              top_k = 20;
              min_p = 0;
              repeat_penalty = 1.08;
              frequency_penalty = 0.15;
              presence_penalty = 0;
            };
          };
          mkStep =
            effort:
            (mkLocal "openai/step-3.7-flash")
            // {
              chat_template_kwargs = {
                reasoning_effort = effort;
              };
            };
          mkGPT =
            effort:
            (mkLocal "openai/gpt-oss-120b")
            // {
              chat_template_kwargs = {
                reasoning_effort = effort;
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
              set_verbose = true;
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
                  model_name = "qwen3.5-122b-a10b";
                  litellm_params = mkLocal "openai/qwen3.5-122b";
                }
                {
                  model_name = "qwen3.6-35b-a3b-general";
                  litellm_params = mkLocalSampled "openai/qwen3.6-35b-a3b-udq8" sampling.general;
                }
                {
                  model_name = "qwen3.6-35b-a3b-coding";
                  litellm_params = mkLocalSampled "openai/qwen3.6-35b-a3b-udq8" sampling.coding;
                }
                {
                  model_name = "qwen3.6-27b-coding";
                  litellm_params = (mkLocalSampled "openai/qwen3.6-27b" sampling.coding) // {
                    api_base = "http://10.0.0.3:8080/v1";
                  };
                }
                {
                  model_name = "qwen3.6-27b-general";
                  litellm_params = (mkLocalSampled "openai/qwen3.6-27b" sampling.general) // {
                    api_base = "http://10.0.0.3:8080/v1";
                  };
                }
                {
                  model_name = "gemma-4-e4b-tool";
                  litellm_params = mkLocalSampled "openai/gemma-4-e4b-q6" sampling.gemmaTool;
                }
                {
                  model_name = "gpt-oss-tool";
                  litellm_params = (mkLocalSampled "openai/gpt-oss-120b" sampling.gptOssTool) // {
                    chat_template_kwargs = {
                      reasoning_effort = "low";
                    };
                  };
                }
                {
                  model_name = "qwen3.5-122b-a10b-tool";
                  litellm_params = mkLocalSampled "openai/qwen3.5-122b" sampling.qwenLargeMoeTool;
                }
                {
                  model_name = "gemma-4-31b";
                  litellm_params = (mkLocal "openai/gemma-4-31b") // {
                    api_base = "http://10.0.0.3:8080/v1";
                  };
                }
                {
                  model_name = "gemma-4-26b-a4b";
                  litellm_params = mkLocal "openai/gemma-4-26b-a4b";
                }
                {
                  model_name = "gemma-4-e4b";
                  litellm_params = mkLocal "openai/gemma-4-e4b-q6";
                }
                {
                  model_name = "gpt-oss-low";
                  litellm_params = mkGPT "low";
                }
                {
                  model_name = "gpt-oss-medium";
                  litellm_params = mkGPT "medium";
                }
                {
                  model_name = "gpt-oss-high";
                  litellm_params = mkGPT "high";
                }
                {
                  model_name = "mistral-small-4-119b";
                  litellm_params = mkLocal "openai/mistral-small-4-119b";
                }
                {
                  model_name = "step-3.7-flash-low";
                  litellm_params = mkStep "low";
                }
                {
                  model_name = "step-3.7-flash-medium";
                  litellm_params = mkStep "medium";
                }
                {
                  model_name = "step-3.7-flash-high";
                  litellm_params = mkStep "high";
                }
                {
                  model_name = "minimax-m2.7";
                  litellm_params = mkLocal "openai/minimax-m2.7";
                }
                {
                  model_name = "qwen3-coder-next";
                  litellm_params = mkLocalSampled "openai/qwen3-coder-next" {
                    temperature = 0.6;
                    top_p = 0.95;
                    top_k = 40;
                    min_p = 0;
                    presence_penalty = 0;
                  };
                }
                {
                  model_name = "qwen3-4b-instruct";
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
          systemd.services.litellm.environment.LITELLM_LOG = "DEBUG";
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
