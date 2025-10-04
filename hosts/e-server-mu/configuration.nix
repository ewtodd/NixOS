{ config, pkgs, inputs, ... }:

{
  imports = [ ./hardware-configuration.nix ./environment.nix ./base.nix ];

  time.timeZone = "America/New_York";
  networking.hostName = "e-laptop";
  system.stateVersion = "24.11";

}
