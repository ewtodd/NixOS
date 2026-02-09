{ lib, osConfig, ... }:
{
  imports = [
    ../default.nix
  ];

  Profile = "play";

  WallpaperPath = lib.mkDefault "/etc/nixos/hosts/${osConfig.networking.hostName}/play.png";
}
