{
  config,
  lib,
  ...
}:
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

      virtualHosts."ntfy.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://127.0.0.1:2586
      '';

      virtualHosts."status.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://127.0.0.1:3001
      '';

      virtualHosts."office.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.2:9980
      '';

      virtualHosts."llm.ethanwtodd.com".extraConfig = ''
        reverse_proxy http://10.0.0.2:4000
      '';
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
