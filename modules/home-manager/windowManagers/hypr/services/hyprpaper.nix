{ osConfig, config, ... }:
let
  wallpaperPath = config.WallpaperPath;
  primaryMonitor = if osConfig.DeviceType == "desktop" then "DP-3" else "eDP-1";
  secondaryMonitor = if osConfig.DeviceType == "desktop" then
    "HDMI-A-1"
  else
    (if osConfig.DeviceType == "laptop" then "HDMI-A-2" else "DP-3");
in {
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "${wallpaperPath}" ];
      wallpaper = [
        "${primaryMonitor},${wallpaperPath}"
        "${secondaryMonitor},${wallpaperPath}"
      ];
    };
  };
}
