{ osConfig, ... }:
{
  imports = [
    ./desktopEnvironment
    ./packages
    ./system-options
    ./theming
    ./xdg
  ];

  Profile = "play";
  WallpaperPath = "/etc/nixos/hosts/${osConfig.networking.hostName}/play.png";

}
