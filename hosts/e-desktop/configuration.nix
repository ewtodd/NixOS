{ ... }:

{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
    ./base.nix
  ];

  time.timeZone = "America/New_York";
  networking.hostName = "e-desktop";
  system.stateVersion = "24.11";

}
