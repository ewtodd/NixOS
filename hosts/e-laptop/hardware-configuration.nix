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
    device = "/dev/disk/by-uuid/a757d672-d76d-47c0-bcba-907397b4c109";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-0acc2573-b664-44f4-b409-8443fa338a4e".device =
    "/dev/disk/by-uuid/0acc2573-b664-44f4-b409-8443fa338a4e";
  boot.initrd.luks.devices."luks-c62cc2af-7c73-4b8e-afd8-4d08eb8fc27f".device =
    "/dev/disk/by-uuid/c62cc2af-7c73-4b8e-afd8-4d08eb8fc27f";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/ACA1-D1E4";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/029a5a42-5427-4d8d-9106-dda86cfdc5a0"; }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
