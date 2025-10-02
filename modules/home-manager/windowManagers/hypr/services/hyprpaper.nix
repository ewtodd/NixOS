{ osConfig, config, ... }:
let
  wallpaperPath = config.WallpaperPath;
  primaryMonitor = if osConfig.DeviceType == "desktop" then "DP-3" else "eDP-1";
  secondaryMonitor =
    if osConfig.DeviceType == "desktop" then "HDMI-A-1" else "HDMI-A-2";
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
