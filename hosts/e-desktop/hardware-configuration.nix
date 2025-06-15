{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  systemd.targets.tpm2 = { enable = false; };
  services.power-profiles-daemon.enable = false;
  powerManagement = {
    enable = true;
    powertop.enable = false;
  };

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm_mod" "btrfs" ];
  boot.kernelModules = [ "kvm-intel" "v4l2loopback" ];
  boot.extraModulePackages = [
    (config.boot.kernelPackages.v4l2loopback.overrideAttrs (old: {
      version = "0.15.0";
      src = pkgs.fetchFromGitHub {
        owner = "umlaeute";
        repo = "v4l2loopback";
        rev = "v0.15.0";
        sha256 = "sha256-fa3f8GDoQTkPppAysrkA7kHuU5z2P2pqI8dKhuKYh04=";
      };
    }))
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';
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
  swapDevices =
    [{ device = "/dev/disk/by-uuid/7a17f4e4-8dca-427f-9138-340e6b4b778f"; }];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
