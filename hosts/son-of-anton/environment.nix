{
  pkgs,
  ...
}:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.firmware = [ pkgs.linux-firmware ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.supportedFilesystems = [ "btrfs" ];

  boot.kernelParams = [
    "amd_pstate=active"
    "amdgpu.gttsize=122880"
    "ttm.pages_limit=31457280"
  ];
}
