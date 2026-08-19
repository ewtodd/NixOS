{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.litellmProxy.enable {
    networking.firewall.allowedTCPPorts = [
      4000
    ];

    systemd.services."container@litellm".restartTriggers = [
      config.age.secrets.litellm-master-key.file
      config.age.secrets.litellm-deepseek-key.file
    ];

    containers.litellm = {
      autoStart = true;

      bindMounts."/run/agenix/litellm-master-key" = {
        hostPath = "/run/agenix/litellm-master-key";
        isReadOnly = true;
      };

      bindMounts."/run/agenix/litellm-deepseek-key" = {
        hostPath = "/run/agenix/litellm-deepseek-key";
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
          sonOfAnton = "http://10.0.0.5:8080/v1"; # 2x R9700 32GB + Strix Halo iGPU

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
            # Qwen3.8 model card recommended sampling per use case.
            qwen38Thinking = {
              temperature = 1.0;
              top_p = 0.95;
              top_k = 20;
              min_p = 0;
              presence_penalty = 0;
            };
            qwen38Instruct = {
              temperature = 0.7;
              top_p = 0.8;
              top_k = 20;
              min_p = 0;
              presence_penalty = 1.5;
              chat_template_kwargs = {
                enable_thinking = false;
              };
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
              litellm_settings = {
                drop_params = false;
                request_timeout = 1800;
              };

              model_list = [
                {
                  model_name = "qwen3.8-27b-coding";
                  litellm_params = mkLocalSampled sonOfAnton "openai/qwen3.8-27b" sampling.qwen38Thinking;
                }
                {
                  model_name = "qwen3.8-27b-instruct";
                  litellm_params = mkLocalSampled sonOfAnton "openai/qwen3.8-27b" sampling.qwen38Instruct;
                }
                {
                  model_name = "qwen3.6-27b-coding";
                  litellm_params = mkLocalSampled sonOfAnton "openai/qwen3.6-27b" sampling.coding;
                }
                {
                  model_name = "qwen3.6-27b-general";
                  litellm_params = mkLocalSampled sonOfAnton "openai/qwen3.6-27b" sampling.general;
                }
                {
                  model_name = "gemma-4-31b";
                  litellm_params = mkLocal sonOfAnton "openai/gemma-4-31b";
                }
                {
                  model_name = "qwen3.6-27b-heretic-coding";
                  litellm_params = mkLocalSampled sonOfAnton "openai/qwen3.6-27b-heretic" sampling.coding;
                }
                {
                  model_name = "qwen3.6-27b-heretic-general";
                  litellm_params = mkLocalSampled sonOfAnton "openai/qwen3.6-27b-heretic" sampling.general;
                }
                {
                  model_name = "gemma-4-31b-heretic";
                  litellm_params = mkLocal sonOfAnton "openai/gemma-4-31b-heretic";
                }

                {
                  model_name = "qwen3.6-35b-a3b";
                  litellm_params = mkLocal sonOfAnton "openai/qwen3.6-35b-a3b";
                }
                {
                  model_name = "deepseek-v4-flash-full";
                  litellm_params = mkLocal sonOfAnton "openai/deepseek-v4-flash-full";
                }
                # Hosted DeepSeek API (api.deepseek.com) — default params,
                # key comes from the agenix env file via $DEEPSEEK_API_KEY.
                # Names are the API's current model IDs (V4 family); they match
                # the opencode/models.dev catalog names one-to-one.
                # Costs are per token, off-peak rates from the DeepSeek pricing
                # page (cache miss for input; cache-hit input billed separately).
                {
                  model_name = "deepseek-v4-flash";
                  litellm_params = {
                    model = "deepseek/deepseek-v4-flash";
                    api_key = "os.environ/DEEPSEEK_API_KEY";
                    input_cost_per_token_float = 0.00000022; # $0.22 / 1M
                    output_cost_per_token_float = 0.00000066; # $0.66 / 1M
                    cache_read_input_token_cost_float = 0.000000007; # $0.007 / 1M
                  };
                }
                {
                  model_name = "deepseek-v4-pro";
                  litellm_params = {
                    model = "deepseek/deepseek-v4-pro";
                    api_key = "os.environ/DEEPSEEK_API_KEY";
                    input_cost_per_token_float = 0.00000066; # $0.66 / 1M
                    output_cost_per_token_float = 0.00000198; # $1.98 / 1M
                    cache_read_input_token_cost_float = 0.000000022; # $0.022 / 1M
                  };
                }
              ];
            };
          };

          environment.etc."litellm/config.yaml".source =
            (pkgs.formats.yaml { }).generate "litellm-config.yaml"
              config.services.litellm.settings;
          systemd.services.litellm.serviceConfig.ExecStart = lib.mkForce (
            lib.concatStringsSep " " [
              (lib.getExe config.services.litellm.package)
              "--host ${config.services.litellm.host}"
              "--port ${toString config.services.litellm.port}"
              "--config /etc/litellm/config.yaml"
            ]
          );
          # Second EnvironmentFile (appended to the module's list) for the
          # DeepSeek API key, keeping it out of the nix store config.
          systemd.services.litellm.serviceConfig.EnvironmentFile = [
            "/run/agenix/litellm-deepseek-key"
          ];

          system.stateVersion = "26.11";
        };
    };
  };
}
