{ ... }:
{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
    ./base.nix
  ];

  time.timeZone = "America/New_York";
  networking.hostName = "e-laptop";
  system.stateVersion = "25.11";

}
