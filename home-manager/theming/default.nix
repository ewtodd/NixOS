{ pkgs, ... }:
{
  imports = [
    ./gtk.nix
    ./qt.nix
  ];

  config = {
    gtk.enable = true;
    home.pointerCursor = {
      enable = true;
      package = pkgs.dracula-theme;
      name = "Dracula-cursors";
    };
  };
}
