{ ... }: {
  imports = [ ./nix-colors.nix ./gtk.nix ./qt.nix ];
  gtk.enable = true;
}
