{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "xe" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/mapper/luks-d3033515-bb52-427d-b809-5684be0eb94f";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-d3033515-bb52-427d-b809-5684be0eb94f".device =
    "/dev/disk/by-uuid/d3033515-bb52-427d-b809-5684be0eb94f";
  boot.initrd.luks.devices."luks-4aa58d65-793d-4ce2-b85c-07f5f37be761".device =
    "/dev/disk/by-uuid/4aa58d65-793d-4ce2-b85c-07f5f37be761";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/51FB-541C";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ { device = "/dev/mapper/luks-4aa58d65-793d-4ce2-b85c-07f5f37be761"; } ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
