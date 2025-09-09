{ config, pkgs, inputs, ... }: {
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;
  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
  };

  boot.kernelParams = [ "quiet" "splash" "video=1920x1080" ];
}
