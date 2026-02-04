{ lib, ... }:
{
  imports = [
    ../packages
    ../system-options
    ../../nixos
    ../../darwin
  ];

  Profile = "play";

  # Platform-specific wallpaper handling (only applies on NixOS)
  WallpaperPath = lib.mkDefault "/etc/nixos/hosts/HOSTNAME_PLACEHOLDER/play.png";
}
