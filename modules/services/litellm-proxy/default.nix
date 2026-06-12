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
        {
          services.litellm = {
            enable = true;
            host = "0.0.0.0";
            port = 4000;
            environmentFile = "/run/agenix/litellm-master-key";

            settings = {
              general_settings.master_key = "os.environ/LITELLM_MASTER_KEY";

              litellm_settings.callbacks = [ "classifier.router" ];

              router_settings.fallbacks = [
                {
                  fast-coder = [
                    "smart-coder"
                    "big-moe"
                  ];
                }
                {
                  smart-coder = [
                    "big-moe"
                    "fast-coder"
                  ];
                }
                {
                  ultra-fast = [
                    "fast-coder"
                    "big-moe"
                  ];
                }
                {
                  big-moe = [
                    "gpt-oss-120b"
                    "fast-coder"
                  ];
                }
                {
                  gpt-oss-120b = [
                    "big-moe"
                    "fast-coder"
                  ];
                }
                # auto is rewritten to a tier by the pre-call hook; this only
                # matters if the hook is ever bypassed.
                {
                  auto = [
                    "big-moe"
                    "fast-coder"
                  ];
                }
              ];

              model_list = [
                {
                  model_name = "fast-coder"; # coding + simple
                  litellm_params = {
                    model = "openai/qwen-coder"; # llama-swap id on e-desktop
                    api_base = "http://10.0.0.4:8080/v1"; # llama-swap (CUDA), e-desktop
                    api_key = "none";
                  };
                }
                {
                  model_name = "smart-coder"; # coding + complex
                  litellm_params = {
                    model = "openai/qwen3-coder-next";
                    api_base = "http://10.0.0.5:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "ultra-fast"; # general + simple
                  litellm_params = {
                    model = "openai/qwen3-30b-a3b";
                    api_base = "http://10.0.0.5:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "big-moe"; # general + complex / orchestrator default
                  litellm_params = {
                    model = "openai/qwen3.5-122b";
                    api_base = "http://10.0.0.5:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  model_name = "gpt-oss-120b";
                  litellm_params = {
                    model = "openai/gpt-oss-120b";
                    api_base = "http://10.0.0.5:8080/v1";
                    api_key = "none";
                  };
                }
                {
                  # Routed entry point. The async_pre_call_hook rewrites this to one
                  # of the four tiers before dispatch; the big-moe mapping here is
                  # only a safe default if the hook is ever bypassed.
                  model_name = "auto";
                  litellm_params = {
                    model = "openai/qwen3.5-122b";
                    api_base = "http://10.0.0.5:8080/v1";
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
