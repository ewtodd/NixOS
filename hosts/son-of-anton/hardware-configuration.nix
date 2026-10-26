{
  config,
  lib,
  pkgs,
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

  powerManagement = {
    enable = true;
    powertop.enable = false;
  };

  # For LACT's fan curves, not overclocking: the R9700s expose fan control only through
  # OverDrive (gpu_od/fan_ctrl).
  hardware.amdgpu.overdrive.enable = true;

  services.lact.settings =
    let
      # The firmware takes exactly five points, keyed on the hotspot (junction) temperature. Its
      # own control let the worse-cooled card sit at 93-107 C under sustained load with the fans
      # near 70%.
      gpu = {
        fan_control_enabled = true;
        fan_control_settings = {
          mode = "curve";
          static_speed = 0.5;
          temperature_key = "junction";
          interval_ms = 500;
          curve = {
            "40" = 0.3;
            "60" = 0.45;
            "75" = 0.65;
            "85" = 0.85;
            "95" = 1.0;
          };
        };
        power_cap = 230.0;
      };
    in
    {
      version = 7;
      daemon = {
        log_level = "info";
        admin_group = "wheel";
        disable_clocks_cleanup = false;
      };
      apply_settings_timer = 5;
      gpus."1002:7551-F111:000A-0000:c7:00.0" = gpu;
      gpus."1002:7551-F111:000A-0000:cc:00.0" = gpu;
    };

  # LACT 0.10 parses a fan curve's temperatures only as YAML integers, and pkgs.formats.yaml quotes
  # every numeric attribute name ('40':), so the module's file fails to load. Same file, keys unquoted.
  environment.etc."lact/config.yaml".source = lib.mkForce (
    pkgs.runCommand "lact-config.yaml" { } ''
      sed -E "s/^( +)'([0-9]+)':/\1\2:/" ${
        (pkgs.formats.yaml { }).generate "lact-config.yaml" config.services.lact.settings
      } > $out
    ''
  );

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/c6abb1e6-dbb4-4a6c-82ff-bba33260da68";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D3A7-AFC2";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/scratch" = {
    device = "/dev/disk/by-uuid/f46e3380-8258-451c-a4dd-7ef5f3dff939";
    fsType = "ext4";
  };

  # 6x Micron 1100 256GB on the ASM1166: two 3-drive RAID 0 arrays (unholy's SSD
  # stream pool and the dev workspace)
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      MAILADDR root
      ARRAY /dev/md/stream metadata=1.2 UUID=77ee4b1d:cf5e9b59:a68e7ab2:094e5110
      ARRAY /dev/md/work metadata=1.2 UUID=b2d2f1c0:bb40cd9c:64ae0989:24df0d8e
    '';
  };

  fileSystems."/stream" = {
    device = "/dev/disk/by-label/stream";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
      "x-systemd.device-timeout=10s"
    ];
  };

  fileSystems."/work" = {
    device = "/dev/disk/by-label/work";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
      "x-systemd.device-timeout=10s"
    ];
  };

  swapDevices = [
    {
      device = "/var/swap";
      size = 32768;
      priority = 10;
    }
  ];
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "30s";
    RebootWatchdogSec = "10min";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
