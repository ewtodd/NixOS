{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.nodeExporter.enable {
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = [ "systemd" ];
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (!config.systemOptions.services.router.enable) [
      9100
    ];
  };
}
