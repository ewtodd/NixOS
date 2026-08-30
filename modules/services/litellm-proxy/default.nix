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
          # The two MCP servers that are not just a nixpkgs binary. Both are
          # spawned as stdio subprocesses of the proxy, inside this container.
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
          sonOfAnton = "http://10.0.0.5:8080/v1"; # llama-swap on Strix (device 2)
          sonOfAntonVllm = "http://10.0.0.5:8100/v1"; # vLLM on R9700s (TP=2)
          oracleSwap = "http://10.0.0.6:8080/v1";

          mkLocal = api_base: model: {
            inherit model api_base;
            api_key = "none";
            allowed_openai_params = nativeOpenaiParams;
            timeout = 1800;
          };
          sampling = {
            qwen35 = {
              temperature = 1.0;
              top_p = 0.95;
              top_k = 20;
              min_p = 0;
              presence_penalty = 1.5;
              repetition_penalty = 1.0;
            };
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
          vllmSlots = 4;
          llamaSlots = 2;
          mkPool =
            name: vllmParams: llamaParams:
            builtins.genList (i: {
              model_name = name;
              litellm_params = vllmParams;
              model_info.id = "${name}-vllm-${toString i}";
            }) vllmSlots
            ++ builtins.genList (i: {
              model_name = name;
              litellm_params = llamaParams;
              model_info.id = "${name}-llama-${toString i}";
            }) llamaSlots;
        in
        {
          services.litellm = {
            enable = true;
            host = "0.0.0.0";
            port = 4000;
            environmentFile = "/run/agenix/litellm-master-key";

            package = inputs.nixpkgs-good.legacyPackages.${pkgs.stdenv.hostPlatform.system}.litellm;

            settings = {
              general_settings.master_key = "os.environ/LITELLM_MASTER_KEY";
              set_verbose = true;
              litellm_settings = {
                drop_params = false;
                request_timeout = 1800;
              };
              router_settings = {
                routing_strategy = "least-busy";
              };

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
                  model_name = "supra-title";
                  litellm_params = mkLocal oracleSwap "openai/supra-title";
                }
                {
                  model_name = "qwen3.8-flash-next";
                  litellm_params = mkLocalSampled sonOfAnton "openai/qwen3.8-flash-next" sampling.qwen38Thinking;
                }
                {
                  model_name = "qwen3.8-flash-next-instruct";
                  litellm_params = mkLocalSampled sonOfAnton "openai/qwen3.8-flash-next" sampling.qwen38Instruct;
                }
                {
                  model_name = "qwen3.5-122b-a10b";
                  litellm_params = mkLocalSampled sonOfAnton "openai/qwen3.5-122b-a10b" sampling.qwen35;
                }
                {
                  model_name = "deepseek-v4-flash-full";
                  litellm_params = mkLocal sonOfAnton "openai/deepseek-v4-flash-full";
                }
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
              ]
              ++ mkPool "qwen3.8-27b-coding" (mkLocalSampled sonOfAntonVllm "openai/Qwen/Qwen3.8-27B-FP8"
                sampling.qwen38Thinking
              ) (mkLocalSampled sonOfAnton "openai/qwen3.8-27b" sampling.qwen38Thinking)
              ++ mkPool "qwen3.8-27b-instruct" (mkLocalSampled sonOfAntonVllm "openai/Qwen/Qwen3.8-27B-FP8"
                sampling.qwen38Instruct
              ) (mkLocalSampled sonOfAnton "openai/qwen3.8-27b" sampling.qwen38Instruct);
            };
          };

          environment.etc."litellm/config.yaml".source =
            (pkgs.formats.yaml { }).generate "litellm-config.yaml"
              config.services.litellm.settings;
          environment.etc."litellm/searxng_mcp.py".source = ./searxng_mcp.py;
          # LiteLLM refuses to spawn a stdio MCP command that is not on this
          # allowlist. Names, not paths: it matches on the basename of the
          # configured command.
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
