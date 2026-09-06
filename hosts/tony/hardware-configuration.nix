{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Comet Lake-U (GPU 8086:9bca, PCH 8086:02c8). The CPU reports as
  # "Genuine Intel(R) CPU 0000" -- an engineering sample, which is normal in
  # cheap mini PCs; 4C/8T at 1.6 GHz base matches an i5-10210U.
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Root is the retired Kingston SNV3S1000G (serial 50026B7283998003) from
  # e-desktop. UUIDs are filled in by the installer -- see hosts/tv/README.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # No swap partition: 8 GB is plenty for a kiosk browser, and zram is both
  # faster and kinder to the SSD.
  swapDevices = [ ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
