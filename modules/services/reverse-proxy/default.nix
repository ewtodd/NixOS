{
  config,
  lib,
  inputs,
  system,
  ...
}:
let
  anubisAi = "127.0.0.1:9001";
  anubisStatus = "127.0.0.1:9002";
  anubisLlm = "127.0.0.1:9003";
in
{
  config = lib.mkIf config.systemOptions.services.reverseProxy.enable {
    services.caddy = {
      enable = true;

      virtualHosts."cache.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.4:5000
      '';
      virtualHosts."cloud.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.2:80
      '';
      virtualHosts."office.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.2:9980
      '';

      # Static generated documentation — no backend, so caddy serves the store
      # paths itself. Doxygen emits only relative links, which is what lets the
      # generated site live under a path prefix. Bare / is a hand-written index
      # of what is published; add a handle_path block and a card in
      # docs-index/index.html together when a project joins.
      virtualHosts."docs.ethanwtodd.com".extraConfig = ''
        encode zstd gzip

        handle_path /analysis-utilities/* {
          root * ${inputs.analysis-utilities.packages.${system}.docs}
          file_server
        }

        handle {
          root * ${./docs-index}
          file_server
        }
      '';

      virtualHosts."status.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://${anubisStatus} {
          header_up X-Real-IP {remote_host}
        }
      '';

      virtualHosts."ai.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://${anubisAi} {
          header_up X-Real-IP {remote_host}
        }
      '';

      # OpenAI-compatible API paths (/v1) are API-key-protected by LiteLLM
      # itself, so they bypass anubis (clients can't solve browser challenges).
      # The LiteLLM dashboard at / goes through anubis.
      virtualHosts."litellm.ethanwtodd.com".extraConfig = ''
        @api path /v1*
        reverse_proxy @api http://10.0.0.6:4000
        reverse_proxy http://${anubisLlm} {
          header_up X-Real-IP {remote_host}
        }
      '';
    };

    services.anubis.instances = {
      ai.settings = {
        TARGET = "http://10.0.0.6:8081";
        BIND = anubisAi;
        BIND_NETWORK = "tcp";
      };
      llm.settings = {
        TARGET = "http://10.0.0.6:4000";
        BIND = anubisLlm;
        BIND_NETWORK = "tcp";
      };
      status.settings = {
        TARGET = "http://127.0.0.1:3001";
        BIND = anubisStatus;
        BIND_NETWORK = "tcp";
      };
    };

    services.endlessh-go = {
      enable = true;
      port = 22;
      openFirewall = true;
      prometheus.enable = true;
      prometheus.listenAddress = "127.0.0.1";
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
