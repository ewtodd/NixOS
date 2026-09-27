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

  # WAN sees only the API surfaces: /v1 (master/client keys), /friend (friend
  # key, scoped to qwen3.8-27b) and /mcp (virtual keys with MCP grants; the
  # friend key has none). All terminate at Bifrost (:4002); handle_path strips
  # the /friend prefix before the upstream sees it. The dashboard, /api and
  # /assets are LAN-only: private source ranges hit Bifrost directly (admin
  # auth still applies), everyone else gets 404.
  llmRoutes = ''
    handle_path /friend/* {
      reverse_proxy http://10.0.0.6:4002
    }
    @api path /v1* /mcp*
    handle @api {
      reverse_proxy http://10.0.0.6:4002
    }
    @lan remote_ip 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
    handle @lan {
      reverse_proxy http://10.0.0.6:4002
    }
    # Scripted clients announce no browser engine in their User-Agent, so skip
    # the challenge and trap them immediately; browser-like clients get the
    # proof-of-work first and then the tarpit.
    @browser header_regexp User-Agent "(?i)(mozilla|webkit|gecko|chrome|crios|firefox|safari|edg/|opr/)"
    @scripted not header_regexp User-Agent "(?i)(mozilla|webkit|gecko|chrome|crios|firefox|safari|edg/|opr/)"
    handle @scripted {
      reverse_proxy http://127.0.0.1:9004
    }
    handle {
      reverse_proxy http://${anubisLlm} {
        header_up X-Real-IP {remote_host}
      }
    }
  '';
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
      # Static generated docs -- no backend, caddy serves the store path itself. The website flake assembles
      # the tree (index at /, each project's doxygen output under its own prefix; doxygen emits only relative
      # links). A project joins by gaining a `docs` URL in its front matter there; nothing here changes.
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

      # Gateway hostname (Bifrost :4002).
      virtualHosts."llm.ethanwtodd.com".extraConfig = llmRoutes;

      # Pure honeypot: nothing legitimate uses this name, so every request is
      # a bot. No Anubis; straight into the tarpit.
      virtualHosts."admin.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://127.0.0.1:9005
      '';
    };

    services.anubis.instances = {
      ai.settings = {
        TARGET = "http://10.0.0.6:8081";
        BIND = anubisAi;
        BIND_NETWORK = "tcp";
      };
      # Only the WAN catch-all hits this; DIFFICULTY 5 is above the default 4,
      # so every challenge costs a scanner noticeably more CPU. Solving it only
      # leads into the HTTP tarpit, which never finishes its response.
      llm.settings = {
        TARGET = "http://127.0.0.1:9004";
        BIND = anubisLlm;
        BIND_NETWORK = "tcp";
        DIFFICULTY = 5;
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
