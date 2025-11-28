{ config, lib, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  systemd.targets.tpm2 = { enable = false; };
  powerManagement = {
    enable = true;
    powertop.enable = false;
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ "dm_mod" "btrfs" "amdgpu" ];
  boot.kernelModules = [ "kvm-intel" "v4l2loopback" ];
  security.polkit.enable = true;
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/23f3ce0e-1ec6-4c43-99c5-e3168f00f08f";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-5cffe834-ffb7-4243-ae39-551518815d10".device =
    "/dev/disk/by-uuid/5cffe834-ffb7-4243-ae39-551518815d10";

  boot.initrd.luks.devices."home" = {
    device = "/dev/disk/by-uuid/bfbb0513-7cd7-4d1e-9cb5-315208156e57";
    allowDiscards = true; # Enable TRIM (if using SSD)
  };

  boot.initrd.luks.devices."games".device =
    "/dev/disk/by-uuid/f9219808-ffc7-41c7-854e-aaaf3d45a675";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/29FA-BB43";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/home";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" "subvol=@home" ];
    depends = [ "/dev/mapper/home" ];
  };

  fileSystems."/games" = {
    device = "/dev/mapper/games";
    fsType = "btrfs";
    depends = [ "/dev/mapper/games" ];
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/7a17f4e4-8dca-427f-9138-340e6b4b778f"; }];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
