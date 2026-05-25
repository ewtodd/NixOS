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
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
