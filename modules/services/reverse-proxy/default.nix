{
  config,
  lib,
  ...
}:
let
  # Anubis sits between Caddy and the browser-facing backends, serving a
  # proof-of-work challenge that costs scrapers/credential bots CPU before they
  # ever reach the app. TCP loopback binds avoid unix-socket permission juggling
  # with Caddy. METRICS_BIND is left at its per-instance unix-socket default.
  anubisAi = "127.0.0.1:9001";
  anubisStatus = "127.0.0.1:9002";
  anubisLlm = "127.0.0.1:9003";
in
{
  config = lib.mkIf config.systemOptions.services.reverseProxy.enable {
    services.caddy = {
      enable = true;

      # Non-browser services stay direct: nix (cache), Nextcloud/Collabora
      # WebDAV sync (cloud/office), ntfy app clients -- a JS PoW wall would break
      # all of these.
      virtualHosts."cache.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.4:5000
      '';
      virtualHosts."cloud.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.2:80
      '';
      virtualHosts."ntfy.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://127.0.0.1:2586
      '';
      virtualHosts."office.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.2:9980
      '';

      # Browser-facing -> behind the Anubis PoW wall. Anubis runs with
      # use-remote-address=false, so it needs the real client IP in an
      # X-Real-IP header (Caddy doesn't send that by default); {remote_host} is
      # the direct peer, i.e. the real client since Caddy is the edge.
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

      # llm is mostly an API (qwen-code hits /v1 + /mcp with a Bearer key and
      # cannot solve a JS challenge), so route those paths straight to LiteLLM
      # and send only the browser UI through Anubis -- walling/tarpitting the UI
      # surface without ever touching the API.
      virtualHosts."llm.ethanwtodd.com".extraConfig = ''
        @api path /v1* /mcp*
        reverse_proxy @api http://10.0.0.5:4000
        reverse_proxy http://${anubisLlm} {
          header_up X-Real-IP {remote_host}
        }
      '';
    };

    # ---- Anubis proof-of-work instances ----
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
        TARGET = "http://10.0.0.5:4000";
        BIND = anubisLlm;
        BIND_NETWORK = "tcp";
      };
    };

    # ---- endlessh tarpit on :22 (the WAN edge) ----
    # Real SSH is 2222 (NAT-forwarded to mu); port 22 is pure bait. endlessh-go
    # drip-feeds an endless random SSH banner, trapping credential bots in stuck
    # connections for hours, and exports Prometheus metrics so the carnage can be
    # graphed in Grafana.
    services.endlessh-go = {
      enable = true;
      port = 22;
      openFirewall = true;
      # Metrics on loopback only -- Prometheus runs on this same host (nu), so no
      # need to expose :2112 on the WAN edge.
      prometheus.enable = true;
      prometheus.listenAddress = "127.0.0.1";
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
