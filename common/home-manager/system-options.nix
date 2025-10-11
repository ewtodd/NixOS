{ lib, ... }:

with lib;

{
  options = {
    Profile = mkOption {
      type = types.enum [ "work" "play" ];
      default = "play";
      description = "Profile for user (work/play)";
    };
    WallpaperPath = mkOption {
      type = types.str;
      default =
        "/etc/nixos/modules/home-manager/windowManagers/sway/wallpapers/eris.png";
      description = "Absolute path for wallpaper location";
    };
    FontChoice = mkOption {
      type = types.enum [
        "JetBrains Mono Nerd Font"
        "FiraCode Nerd Font"
        "SpaceMono Nerd Font"
        "Ubuntu Nerd Font"
      ];
      default = "JetBrains Mono Nerd Font";
      description = "Font";
    };
  };
}
