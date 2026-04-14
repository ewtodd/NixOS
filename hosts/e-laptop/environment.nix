{
  pkgs,
  lib,
  ...
}:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.fwupd = {
    enable = true;
  };

  boot.initrd.systemd.enable = true;

  security.tpm2 = {
    enable = false;
  };
  systemd.units."dev-tpm0.device".enable = false;
  systemd.services.systemd-tpm2-setup.enable = false;
  systemd.services.systemd-tpm2-setup-early.enable = false;

  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.loader.efi.canTouchEfiVariables = true;

  boot.resumeDevice = "/dev/disk/by-uuid/63cf64c5-e1bd-42ed-a0c6-e3e8cc21634d";
}
