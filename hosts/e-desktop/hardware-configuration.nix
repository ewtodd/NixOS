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
    version = 7;
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
    # ahci is what reaches the two Micron SATA SSDs holding the homes; both are
    # unlocked in the initrd, so it has to be here and not just in kernelModules.
    "sd_mod"
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

  # Storage: 2TB NVMe (p1 ESP -> /boot, p2 LUKS ext4 -> /, p3 LUKS btrfs -> /analysis); two Micron 1100 SATA
  # SSDs, one per user (LUKS + btrfs); 4TB WD SN5100 unchanged (/games, /labdata via pam_mount).
  # cryptroot/home-play/home-work share one passphrase on purpose: systemd-cryptsetup retries it on the
  # others so boot asks exactly once (and the mu bastion's stored passphrase keeps working remotely).

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/7e487738-412c-4308-8cf0-3140ef0bd47e";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/ad6bb757-9b3f-4843-9414-05eb72b51b55";
    allowDiscards = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3522-5CAC";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  boot.initrd.luks.devices."home-play" = {
    device = "/dev/disk/by-uuid/2b1daffa-6dfa-456c-b5a2-7c05caa7d619";
    allowDiscards = true;
  };

  fileSystems."/home/e-play" = {
    device = "/dev/disk/by-uuid/e10f805e-bb6c-45dc-956d-1c149586d0c0";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      "subvol=@play"
    ];
  };

  boot.initrd.luks.devices."home-work" = {
    device = "/dev/disk/by-uuid/2b3fd31d-3690-40a7-8455-310752e9bb19";
    allowDiscards = true;
  };

  fileSystems."/home/e-work" = {
    device = "/dev/disk/by-uuid/81e5b703-a185-4728-8621-039dc4a13214";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      "subvol=@work"
    ];
  };

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
