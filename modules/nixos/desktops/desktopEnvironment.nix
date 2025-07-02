{ lib, ... }: {
  imports = [
    ./sway/sway-de.nix
    ./papersway/papersway-de.nix
    ./niri/niri-de.nix
    ./cosmic/cosmic-de.nix
  ];
}
