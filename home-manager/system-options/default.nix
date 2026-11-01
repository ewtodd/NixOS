{ lib, ... }:
with lib;
{
  options = {
    Profile = mkOption {
      type = types.enum [
        "work"
        "play"
        "root"
      ];
      default = "play";
      description = "Profile for user (work/play)";
    };

    WallpaperPath = mkOption {
      type = types.path;
      description = "Absolute path for wallpaper location. When unset, one is generated from the active base16 scheme.";
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
