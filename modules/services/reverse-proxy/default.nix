{
  config,
  lib,
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

      virtualHosts."llm.ethanwtodd.com".extraConfig = ''
        @api path /v1* /mcp*
        reverse_proxy @api http://10.0.0.6:4000
        reverse_proxy http://${anubisLlm} {
          header_up X-Real-IP {remote_host}
        }
      '';

      virtualHosts."temple.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.6:42123
      '';
    };

    services.anubis.instances = {
      ai.settings = {
        TARGET = "http://10.0.0.5:3080";
        BIND = anubisAi;
        BIND_NETWORK = "tcp";
      };
      status.settings = {
        TARGET = "http://127.0.0.1:3001";
        BIND = anubisStatus;
        BIND_NETWORK = "tcp";
      };
      llm.settings = {
        TARGET = "http://10.0.0.6:4000";
        BIND = anubisLlm;
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
