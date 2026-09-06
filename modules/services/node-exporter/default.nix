{
  config,
  lib,
  ...
}:
{
  options.systemOptions.services.nodeExporter.textfileDir = lib.mkOption {
    type = lib.types.str;
    default = "/var/lib/node-exporter/textfile";
    description = ''
      Directory the textfile collector reads, for metrics node_exporter has no
      collector for (ZFS pool health, for one: the built-in zfs collector
      exposes ARC/ABD kstats only, nothing about pool state).
    '';
  };

  config = lib.mkIf config.systemOptions.services.nodeExporter.enable {
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = [
        "systemd"
        "textfile"
      ];
      extraFlags = [
        "--collector.textfile.directory=${config.systemOptions.services.nodeExporter.textfileDir}"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${config.systemOptions.services.nodeExporter.textfileDir} 0755 root root - -"
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf (!config.systemOptions.services.router.enable) [
      9100
    ];
  };
}
