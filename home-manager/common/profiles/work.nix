{ lib, ... }:
{
  imports = [
    ../packages
    ../system-options
    ../../nixos
    ../../darwin
  ];

  Profile = "work";

  # Platform-specific wallpaper handling (only applies on NixOS)
  WallpaperPath = lib.mkDefault "/etc/nixos/hosts/HOSTNAME_PLACEHOLDER/work.png";
}
