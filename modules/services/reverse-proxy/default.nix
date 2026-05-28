{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.reverseProxy.enable {
    services.caddy = {
      enable = true;
      # Cache lives on e-desktop; reach it over the trusted LAN
      # via its static DHCP lease. Plain http upstream is fine — TLS terminates
      # at Caddy and the hop is on-LAN.
      virtualHosts."cache.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.4:5000
      '';

      # Nextcloud on mu. Nextcloud's own nginx vhost serves the .well-known
      # CalDAV/CardDAV redirects, so Caddy just passes through.
      virtualHosts."cloud.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.2:80
      '';

      # ntfy runs locally on nu. reverse_proxy handles the WebSocket/SSE
      # upgrade for live subscriptions automatically.
      virtualHosts."ntfy.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://127.0.0.1:2586
      '';

      # Collabora Online (Nextcloud Office) on mu. Caddy v2 auto-upgrades the
      # websocket connections coolwsd needs.
      virtualHosts."office.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.2:9980
      '';
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
