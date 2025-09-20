{ pkgs, ... }: {
  boot.kernelPackages = pkgs.linuxPackages_zen;
  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
  };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "iomem=relaxed"
    "resume=/dev/disk/by-uuid/125110a9-9ead-4526-bd82-a7f208b2ec3b"
  ];
  boot.resumeDevice = "/dev/disk/by-uuid/125110a9-9ead-4526-bd82-a7f208b2ec3b";

}
