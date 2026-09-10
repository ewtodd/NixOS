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

      # The apex: a static hugo site, served straight out of the store like the
      # documentation. Its root-absolute asset paths are correct here because it
      # is served at / rather than under a prefix.
      virtualHosts."ethanwtodd.com".extraConfig = ''
        encode zstd gzip
        root * ${inputs.website.packages.${system}.default}
        file_server
      '';

      # One canonical hostname, so links and search results do not split across
      # the two. Needs its own Namecheap record; see the dyndns subdomain list.
      virtualHosts."www.ethanwtodd.com".extraConfig = ''
        redir https://ethanwtodd.com{uri} permanent
      '';

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
      # path itself. The website flake assembles the whole tree: the index at /,
      # and each project's doxygen output under its own prefix (doxygen emits
      # only relative links, which is what lets it live under one). A project
      # joins by gaining a `docs` URL in its page front matter there; nothing
      # here changes.
      virtualHosts."docs.ethanwtodd.com".extraConfig = ''
        encode zstd gzip
        root * ${inputs.website.packages.${system}.docs}
        file_server
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
