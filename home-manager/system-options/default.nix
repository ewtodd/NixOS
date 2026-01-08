{ lib, osConfig, ... }:
with lib;
{
  options = {
    Profile = mkOption {
      type = types.enum [
        "work"
        "play"
      ];
      default = "play";
      description = "Profile for user (work/play)";
    };

    WallpaperPath = mkOption {
      type = types.str;
      default = "/etc/nixos/hosts/${osConfig.networking.hostName}/wallpaper.png";
      description = "Absolute path for wallpaper location";
    };

    Owner = mkOption {
      type = types.enum [
        "e"
        "v"
      ];
      description = "For whom to generate settings";
    };
  };
}
