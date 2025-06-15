{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./environment.nix ./base.nix ];

  time.timeZone = "America/Chicago";
  networking.hostName = "v-desktop";
  system.stateVersion = "25.05";

}
