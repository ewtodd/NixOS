{ lib, ... }: {
  imports = [
    ./sway/sway-de.nix
    ./niri/niri-de.nix
    ./cosmic/cosmic-de.nix
  ];
}
