{ config, pkgs, inputs, ... }:

{
  imports = [ ./hardware-configuration.nix ./environment.nix ./base.nix ];

  time.timeZone = "America/New_York";
  network.hostName = "e-laptop";
  system.stateVersion = "24.11";

}
