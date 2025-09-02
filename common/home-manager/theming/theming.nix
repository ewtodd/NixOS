{ ... }: {
  imports = [ ./gtk.nix ./qt.nix ];
  gtk.enable = true;
}
