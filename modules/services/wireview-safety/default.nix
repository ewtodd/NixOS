{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.wireview-safety.enable {
    # Safety watchdog: watches the wireview-monitor exporter and powers the
    # machine off when a dangerous condition (fault bit or over-temperature)
    # is sustained across consecutive checks. Redundancy behind the mains
    # switch the WireView fault output is wired into.
    systemd.services.wireview-safety = {
      description = "WireView safety watchdog (power off on sustained dangerous conditions)";
      wantedBy = [ "multi-user.target" ];
      after = [ "wireview-monitor.service" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.python3}/bin/python3 ${./safety.py}";
        Restart = "always";
        RestartSec = 2;
        Environment = [
          "WV_METRICS_URL=${config.systemOptions.services.wireview-safety.metricsUrl}"
          "WV_POLL_SECONDS=${toString config.systemOptions.services.wireview-safety.pollIntervalSeconds}"
          "WV_CONSECUTIVE=${toString config.systemOptions.services.wireview-safety.consecutiveHits}"
          "WV_TEMP_THRESHOLD_C=${toString config.systemOptions.services.wireview-safety.tempThresholdC}"
          "WV_TRIGGER_FAULTS=${
            if config.systemOptions.services.wireview-safety.triggerOnFaults then "1" else "0"
          }"
          "WV_ACTION=${config.systemOptions.services.wireview-safety.action}"
          "WV_DRY_RUN=${if config.systemOptions.services.wireview-safety.dryRun then "1" else "0"}"
        ];
      };
    };
  };
}
