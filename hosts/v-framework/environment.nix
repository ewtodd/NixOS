{ config, pkgs, inputs, ... }: {
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  services.scx.enable = true;
  boot.kernelParams = [ "quiet" "splash"];
}
