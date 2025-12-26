{ pkgs, ... }:
{
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.initrd.luks.devices."luks-0c8c96c9-7128-4635-8958-2e2cead680a0".device =
    "/dev/disk/by-uuid/0c8c96c9-7128-4635-8958-2e2cead680a0";

  boot.kernelPackages = pkgs.linuxPackages_xanmod_stable;

  boot.resumeDevice = "/dev/disk/by-uuid/7a17f4e4-8dca-427f-9138-340e6b4b778f"; # Your swap partition UUID
  boot.kernelParams = [ "resume=0c8c96c9-7128-4635-8958-2e2cead680a0" ];

}
