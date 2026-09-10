{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  services.fwupd = {
    enable = true;
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/mapper/luks-d3033515-bb52-427d-b809-5684be0eb94f";
    fsType = "ext4";
  };

  # allowDiscards passes TRIM through dm-crypt to the NVMe. Without it the drive's
  # FTL never learns which blocks are free: garbage collection starves and mixed
  # read/write load stalls for 100-300ms at a time. Tradeoff is that an attacker
  # with access to the disk can see which blocks are unused.
  boot.initrd.luks.devices."luks-d3033515-bb52-427d-b809-5684be0eb94f" = {
    device = "/dev/disk/by-uuid/d3033515-bb52-427d-b809-5684be0eb94f";
    allowDiscards = true;
  };
  boot.initrd.luks.devices."luks-4aa58d65-793d-4ce2-b85c-07f5f37be761" = {
    device = "/dev/disk/by-uuid/4aa58d65-793d-4ce2-b85c-07f5f37be761";
    allowDiscards = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/51FB-541C";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ { device = "/dev/mapper/luks-4aa58d65-793d-4ce2-b85c-07f5f37be761"; } ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
