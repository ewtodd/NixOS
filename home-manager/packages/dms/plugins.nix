{ osConfig, lib, ... }:
let
  deviceType = if (osConfig.systemOptions.deviceType.desktop.enable) then "desktop" else "laptop";
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
