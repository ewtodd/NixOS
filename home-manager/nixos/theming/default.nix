{ pkgs, lib, ... }:
let
  isLinux = pkgs.stdenv.isLinux;
in
{
  imports = [
    ./gtk.nix
    ./qt.nix
  ];

  config = lib.mkIf isLinux {
    gtk.enable = true;
    home.pointerCursor = {
      package = pkgs.dracula-theme;
      name = "Dracula-cursors";
    };
  };
}
