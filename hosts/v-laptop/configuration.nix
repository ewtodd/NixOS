{ ... }:
{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
    ./base.nix
  ];

  time.timeZone = "America/Chicago";
  networking.hostName = "v-laptop";
  system.stateVersion = "25.05";
}
