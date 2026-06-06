{
  lib,
  pkgs,
  ...
}:
{

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.firmware = [ pkgs.linux-firmware ];

  boot.initrd.systemd.enable = true;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.plymouth.enable = lib.mkForce false;
}
