{ lib, osConfig, ... }:
{
  imports = [
    ../default.nix
  ];

  Profile = "work";

  WallpaperPath = lib.mkDefault "/etc/nixos/hosts/${osConfig.networking.hostName}/work.png";
}
