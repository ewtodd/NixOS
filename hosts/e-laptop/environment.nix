{
  pkgs,
  ...
}:
{

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;
  hardware.firmware = [ pkgs.linux-firmware ];

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

  boot.loader.systemd-boot.enable = true;

  boot.loader.efi.canTouchEfiVariables = true;

  boot.resumeDevice = "/dev/disk/by-uuid/029a5a42-5427-4d8d-9106-dda86cfdc5a0";
}
