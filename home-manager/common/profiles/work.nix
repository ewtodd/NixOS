{ lib, osConfig, ... }:
{
  imports = [
    ../packages
    ../system-options
    ../../nixos
    ../../darwin
  ];

  Profile = "work";

  # Platform-specific wallpaper handling (only applies on NixOS)
  WallpaperPath = lib.mkDefault "/etc/nixos/hosts/${osConfig.networking.hostName}/work.png";
}
