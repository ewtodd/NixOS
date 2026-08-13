{
  config,
  lib,
  ...
}:
let
  cfg = config.systemOptions.services.scheduledReboot;
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.scheduled-reboot = {
      description = "Scheduled system reboot";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${config.systemd.package}/bin/systemctl reboot";
      };
    };

    systemd.timers.scheduled-reboot = {
      description = "Timer for scheduled system reboot";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.calendar;
        # Don't catch up a missed reboot on the next boot — otherwise a
        # machine that was off at the scheduled time would reboot the moment
        # it comes back up, which can cascade into a loop.
        Persistent = false;
        RandomizedDelaySec = "120";
      };
    };
  };
}
