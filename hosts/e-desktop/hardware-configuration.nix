{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  systemd.targets.tpm2 = {
    enable = false;
  };

  services.fwupd = {
    enable = true;
  };

  security.tpm2 = {
    enable = false;
  };

  powerManagement = {
    enable = true;
    powertop.enable = false;
    cpuFreqGovernor = lib.mkForce "performance";
  };

  services.hardware.bolt.enable = true;

  services.lact.settings = {
    version = 5;
    daemon = {
      log_level = "info";
      admin_group = "wheel";
      disable_clocks_cleanup = false;
    };
    apply_settings_timer = 5;
    gpus."10DE:2684-1458:40BF-0000:01:00.0" = {
      fan_control_enabled = false;
      power_cap = 430.0;
      gpu_clock_offsets = {
        "0" = 130;
      };
      mem_clock_offsets = {
        "0" = 3250;
      };
    };
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "thunderbolt"
  ];

  boot.initrd.kernelModules = [
    "dm_mod"
    "btrfs"
    "usbhid"
    "hid"
  ];

  boot.kernelModules = [
    "kvm-amd"
    "v4l2loopback"
  ];

  boot.kernelParams = [
    "amd_pstate=active"
    "r8169.aspm=0"
  ];

  systemd.settings.Manager = {
    RuntimeWatchdogSec = "30s";
    RebootWatchdogSec = "10min";
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", ATTRS{vendor}=="0x1002", ATTRS{device}=="0x13c0", SYMLINK+="dri/igpu-render"
    SUBSYSTEM=="input", ACTION=="add|change", ATTRS{idVendor}=="3554", ATTRS{idProduct}=="fa09", TAG-="power-switch"
  '';
  boot.blacklistedKernelModules = lib.mkIf config.systemOptions.graphics.nvidia.enable [ "nouveau" ];
  boot.supportedFilesystems = [ "btrfs" ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  swapDevices = [
    {
      device = "/var/swap";
      size = 32768;
      priority = 10;
    }
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 10; # don't swap eagerly
    "vm.vfs_cache_pressure" = 50;
    "vm.watermark_scale_factor" = 200; # start reclaim earlier
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/23f3ce0e-1ec6-4c43-99c5-e3168f00f08f";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-5cffe834-ffb7-4243-ae39-551518815d10".device =
    "/dev/disk/by-uuid/5cffe834-ffb7-4243-ae39-551518815d10";

  boot.initrd.luks.devices."home" = {
    device = "/dev/disk/by-uuid/bfbb0513-7cd7-4d1e-9cb5-315208156e57";
    allowDiscards = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/12CE-A600";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/home";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      "subvol=@home"
    ];
    depends = [ "/dev/mapper/home" ];
  };

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
