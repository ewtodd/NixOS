{
  lib,
  pkgs,
  ...
}:
{

  boot.kernelPackages = pkgs.linuxPackages_zen;
  hardware.firmware = [ pkgs.linux-firmware ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.plymouth.enable = lib.mkForce false;
}
