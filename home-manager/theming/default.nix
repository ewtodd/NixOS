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
      package = pkgs.comixcursors.Opaque_Black;
      name = "ComixCursors-Opaque-Black";
    };
  };
}
