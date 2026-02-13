{ unstable, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = unstable.linuxPackages_latest;

  boot.kernelParams = [
    "quiet"
    "splash"
    "video=1920x1080"
  ];
}
