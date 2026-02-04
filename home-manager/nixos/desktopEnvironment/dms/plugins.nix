{ osConfig, lib, pkgs, ... }:
let
  isLinux = pkgs.stdenv.isLinux;
  deviceType = if (osConfig.systemOptions.deviceType.desktop.enable) then "desktop" else "laptop";
in
{
  config = lib.mkIf isLinux {
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
  };

}
