{ config, pkgs, inputs, ... }:

{
  imports = [ ./hardware-configuration.nix ./environment.nix ./base.nix ];

  time.timeZone = "America/New_York";
  networking.hostName = "server-mu";
  system.stateVersion = "25.05";

}
