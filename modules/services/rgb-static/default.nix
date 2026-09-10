{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.rgbStatic;

  pythonEnv = pkgs.python3.withPackages (ps: [ ps.openrgb-python ]);

  rgb-static = pkgs.writeShellApplication {
    name = "rgb-static";
    runtimeInputs = [ pythonEnv ];
    text = ''
      exec python3 ${./rgb_static.py} "$@"
    '';
  };

  command = lib.concatStringsSep " " [
    "${rgb-static}/bin/rgb-static"
    "--default-color ${cfg.defaultColor}"
    "--device-colors ${lib.escapeShellArg (builtins.toJSON cfg.deviceColors)}"
    "--expect-devices ${toString cfg.expectedDevices}"
  ];

  # The controllers are not battery-backed: a hardware effect comes back after
  # a power cycle, and Direct-mode state does not always survive S3, so the
  # colours are re-applied on resume as well as at boot.
  sleepTargets = [
    "suspend.target"
    "hibernate.target"
    "hybrid-sleep.target"
    "suspend-then-hibernate.target"
  ];

  # Deliberately not Type=oneshot: this waits for device detection and then
  # re-applies over the following seconds, and a oneshot would hold up
  # multi-user.target (and so the login screen) for all of it. Type=simple is
  # considered started immediately and the passes finish in the background;
  # RemainAfterExit keeps the unit readable in `systemctl status` afterwards.
  unit = {
    Type = "simple";
    RemainAfterExit = true;
    ExecStart = command;
  };
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.systemOptions.hardware.openRGB.enable;
        message = "systemOptions.services.rgbStatic needs systemOptions.hardware.openRGB.enable for the SDK server it talks to.";
      }
      {
        assertion = !config.systemOptions.services.rgbLoad.enable;
        message = "systemOptions.services.rgbStatic and services.rgbLoad both drive the same OpenRGB devices; enable only one.";
      }
    ];

    systemd.services.rgb-static = {
      description = "Apply static OpenRGB colours";
      wantedBy = [ "multi-user.target" ];
      after = [ "openrgb.service" ];
      wants = [ "openrgb.service" ];
      serviceConfig = unit;
    };

    systemd.services.rgb-static-resume = {
      description = "Re-apply static OpenRGB colours after resume";
      wantedBy = sleepTargets;
      after = sleepTargets;
      serviceConfig = unit;
    };
  };
}
