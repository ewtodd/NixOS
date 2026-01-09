{ osConfig, ... }:
{
  imports = [
    ./desktopEnvironment
    ./packages
    ./system-options
    ./theming
    ./xdg
  ];

  Profile = "work";
  WallpaperPath = "/etc/nixos/hosts/${osConfig.networking.hostName}/work.png";

}
