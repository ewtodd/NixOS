{ pkgs, ... }:
{
  systemOptions = {
    owner.e.enable = true;
    nixos-vms.enable = true;
    nixos-vms.work.enable = true;
    nixos-vms.work.autoStart = true;
    nixos-vms.play.enable = true;
    nixos-vms.play.autoStart = false;
  };

  system.primaryUser = "e-darwin";

  networking.hostName = "e-darwin";
  networking.computerName = "e-darwin";
  system.defaults.smb.NetBIOSName = "e-darwin";

  system.configurationRevision = null;
  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.e-darwin = {
    name = "e-darwin";
    home = "/Users/e-darwin";
    shell = pkgs.zsh;
  };
}
