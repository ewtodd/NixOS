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

    # Prometheus (on nu) scrapes this over the LAN. nu is the only WAN-facing
    # host: opening 9100 globally there would expose it externally, but nu's
    # LAN interface is already trusted and Prometheus scrapes nu's own
    # exporter via loopback, so no rule is needed there. Every other host is
    # LAN-only by topology, so opening the port is safe.
    networking.firewall.allowedTCPPorts = lib.mkIf (
      !config.systemOptions.services.router.enable
    ) [ 9100 ];
  };
}
