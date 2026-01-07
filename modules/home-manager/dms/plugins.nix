{ osConfig, lib, ... }:
let
  deviceType = osConfig.DeviceType;
in
{
  programs.dank-material-shell = {
    managePluginSettings = true;
    plugins = {
      dankPomodoroTimer = {
        enable = true;
      };
      calculator = {
        enable = true;
      };
      dankLauncherKeys = {
        enable = true;
      };
      dankBatteryAlerts = lib.mkIf (deviceType == "laptop") {
        enable = true;
      };
    };
  };

}
