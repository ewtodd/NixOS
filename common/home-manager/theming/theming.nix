{ pkgs, ... }:
{
  imports = [
    ./gtk.nix
    ./qt.nix
  ];
  gtk.enable = true;
  home.pointerCursor = {
    package = pkgs.dracula-theme;
    name = "Dracula-cursors";
  };
}
