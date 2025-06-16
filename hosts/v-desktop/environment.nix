{ config, pkgs, inputs, ... }: {
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_6_12;
  services.scx.enable = true;

  boot.initrd.luks.devices."luks-00b35d99-ad18-4fbc-99af-1b176dc2b9dd".device =
    "/dev/disk/by-uuid/00b35d99-ad18-4fbc-99af-1b176dc2b9dd";
}
