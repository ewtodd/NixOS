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
      description = "Scheduled system ${cfg.action}";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${config.systemd.package}/bin/systemctl ${cfg.action}";
      };
    };

    systemd.timers.scheduled-reboot = {
      description = "Timer for scheduled system ${cfg.action}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.calendar;
        # Don't catch up a missed run on the next boot — otherwise a machine
        # that was off at the scheduled time would act the moment it comes
        # back up. For reboot that cascades into a loop; for poweroff it is
        # worse, since waking the machine would immediately shut it down again.
        Persistent = false;
        RandomizedDelaySec = "120";
      };
    };
  };
}
