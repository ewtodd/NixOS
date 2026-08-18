{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.wireview-monitor.enable {
    # Headless WireView Pro II Prometheus exporter (wireview-monitor python
    # daemon). Runs as root so /dev/ttyACM* access does not depend on group
    # membership or the repo's udev rule; binds 0.0.0.0 so the fleet
    # Prometheus (nu) can scrape it over the LAN.
    systemd.services.wireview-monitor = {
      description = "WireView Pro II Prometheus exporter";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart =
          "${inputs.wireview-linux.packages.${pkgs.system}."wireview-monitor"}/bin/wireview-monitor --listen "
          + config.systemOptions.services.wireview-monitor.listenAddress
          + ":${toString config.systemOptions.services.wireview-monitor.port}";
        Restart = "always";
        RestartSec = 3;
      };
    };

    # Same open-port policy as node-exporter: the LAN is trusted.
    networking.firewall.allowedTCPPorts = [ config.systemOptions.services.wireview-monitor.port ];
  };
}
