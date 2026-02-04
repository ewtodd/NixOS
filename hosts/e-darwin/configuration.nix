{ lib, pkgs, ... }:
{
  systemOptions = {
    owner.e.enable = true;
  };

  system.primaryUser = "e-host";

  networking.hostName = "e-darwin";
  networking.computerName = "e-darwin";
  system.defaults.smb.NetBIOSName = "e-darwin";

  system.configurationRevision = null;
  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.e-host = {
    name = "e-host";
    home = "/Users/e-host";
    shell = pkgs.zsh;
  };
}
