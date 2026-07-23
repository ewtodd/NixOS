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
          # Inference hosts on the LAN:
          sonOfAnton = "http://10.0.0.5:8080/v1"; # Strix Halo 128GB — deepseek only
          anton = "http://10.0.0.3:8080/v1"; # R9700 32GB — qwen + gemma

          mkLocal = api_base: model: {
            inherit model api_base;
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
            deterministic = {
              temperature = 0.0;
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
              chat_template_kwargs = {
                enable_thinking = false;
              };
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
          mkDeepseek =
            effort:
            (mkLocal sonOfAnton "openai/deepseek-v4-flash")
            // {
              chat_template_kwargs = {
                reasoning_effort = effort;
              };
            };
          mkLocalSampled =
            api_base: model: profile:
            (mkLocal api_base model) // profile;
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
                  model_name = "qwen3.6-27b-coding";
                  litellm_params = mkLocalSampled anton "openai/qwen3.6-27b" sampling.coding;
                }
                {
                  model_name = "qwen3.6-27b-general";
                  litellm_params = mkLocalSampled anton "openai/qwen3.6-27b" sampling.general;
                }
                {
                  model_name = "gemma-4-31b";
                  litellm_params = mkLocal anton "openai/gemma-4-31b";
                }
                {
                  model_name = "qwen3.6-27b-heretic-coding";
                  litellm_params = mkLocalSampled anton "openai/qwen3.6-27b-heretic" sampling.coding;
                }
                {
                  model_name = "qwen3.6-27b-heretic-general";
                  litellm_params = mkLocalSampled anton "openai/qwen3.6-27b-heretic" sampling.general;
                }
                {
                  model_name = "gemma-4-31b-heretic";
                  litellm_params = mkLocal anton "openai/gemma-4-31b-heretic";
                }
                {
                  model_name = "deepseek-v4-flash-max";
                  litellm_params = mkDeepseek "max";
                }
                {
                  model_name = "deepseek-v4-flash-high";
                  litellm_params = mkDeepseek "high";
                }
                {
                  model_name = "deepseek-v4-flash-no-thinking";
                  litellm_params = (mkLocal sonOfAnton "openai/deepseek-v4-flash") // {
                    chat_template_kwargs = {
                      enable_thinking = false;
                    };
                  };
                }
                {
                  model_name = "gemma-4-e4b-router";
                  litellm_params = mkLocalSampled sonOfAnton "openai/gemma-4-e4b-router" sampling.gemmaTool;
                }
              ];
            };
          };

          environment.etc."litellm/config.yaml".source =
            (pkgs.formats.yaml { }).generate "litellm-config.yaml"
              config.services.litellm.settings;
          environment.etc."litellm/searxng_mcp.py".source = ./searxng_mcp.py;
          environment.etc."litellm/litellm_metrics.py".source = ./litellm_metrics.py;
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
