{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf (config.systemOptions.graphics.amd.enable) {
      hardware.graphics = {
        enable = true;
        package = pkgs.mesa;
        enable32Bit = true;
        package32 = pkgs.driversi686Linux.mesa;
        extraPackages = with pkgs; [
          vulkan-tools
          rocmPackages.clr.icd
        ];
      };

      environment.systemPackages = with pkgs; [
        rocmPackages.rocminfo
        rocmPackages.rocm-smi
        nvtopPackages.amd
        lm_sensors
      ];
    })
    (lib.mkIf (config.systemOptions.graphics.nvidia.enable) {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        open = true;
        nvidiaSettings = false;
        powerManagement = {
          enable = true;
          finegrained = false;
        };
        nvidiaPersistenced = true;
        package = config.boot.kernelPackages.nvidiaPackages.production;
      };
      boot.extraModprobeConfig = ''
        options nvidia-uvm uvm_disable_hmm=1
        options nvidia NVreg_UsePageAttributeTable=1 NVreg_InitializeSystemMemoryAllocations=0
      '';
      boot.blacklistedKernelModules = [ "nouveau" ];

      services.lact.enable = true;

      environment.systemPackages = with pkgs; [
        vulkan-tools
        lm_sensors
        nvtopPackages.nvidia
      ];

      environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool.json".text = ''
        {
          "rules": [
            {
              "pattern": { "feature": "procname", "matches": "niri" },
              "profile": "Limit Free Buffer Pool"
            },
            {
              "pattern": { "feature": "procname", "matches": "quickshell" },
              "profile": "Limit Free Buffer Pool"
            }
          ],
          "profiles": [{
            "name": "Limit Free Buffer Pool",
            "settings": [{ "key": "GLVidHeapReuseRatio", "value": 0 }]
          }]
        }
      '';
    })
    (lib.mkIf (config.systemOptions.graphics.intel.enable) {
      hardware.graphics = {
        enable = true;
        package = pkgs.mesa;
        enable32Bit = true;
        package32 = pkgs.driversi686Linux.mesa;
        extraPackages = with pkgs; [
          vpl-gpu-rt
          intel-media-driver
        ];

        extraPackages32 = with pkgs.pkgsi686Linux; [ intel-vaapi-driver ];
      };
      environment.systemPackages = with pkgs; [
        lm_sensors
      ];
    })
    (lib.mkIf (config.systemOptions.graphics.asahi.enable) {
      hardware.graphics = {
        enable = true;
        package = pkgs.mesa;
        extraPackages = with pkgs; [
          vulkan-tools
        ];
      };
      environment.systemPackages = with pkgs; [
        lm_sensors
      ];
    })
    (lib.mkIf (config.systemOptions.hardware.chromebook-audio.enable) {
      hardware.banshee-audio.enable = true;
    })
    (lib.mkIf (config.systemOptions.hardware.xbox.enable) {
      hardware.xpadneo.enable = true;
      hardware.bluetooth.settings = {
        General = {
          Privacy = "device";
          JustWorksRepairing = "always";
          Class = "0x000100";
          FastConnectable = "true";
        };
      };
    })
    (lib.mkIf (config.systemOptions.hardware.suzyqable.enable) {
      environment.systemPackages = with pkgs; [
        openocd
        screen
        minicom
        usbutils
        libusb1
        flashrom
      ];
      services.udev.extraRules = ''
        # SuzyQable debug cable
        SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="5014", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="5014", MODE="0666", GROUP="dialout"
      '';
    })
    (lib.mkIf (config.systemOptions.hardware.fingerprint.enable) {
      systemd.services.fprintd = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "simple";
      };
      services.fprintd.enable = true;
      security.pam.services.dankshell = {
        u2fAuth = false;
        fprintAuth = false;
      };
    })
    (lib.mkIf (config.systemOptions.hardware.openRGB.enable) {
      environment.systemPackages = with pkgs; [ i2c-tools ];
      services.hardware.openrgb = {
        enable = true;
        motherboard = "intel";
        package = pkgs.openrgb-with-all-plugins;
      };
      hardware.i2c.enable = true;
    })
    (lib.mkIf (config.systemOptions.deviceType.laptop.enable) {
      services.tuned = {
        enable = true;
      };
      services.hardware.bolt.enable = true;
    })
    (lib.mkIf (config.systemOptions.hardware.frameworkLaptop.enable) {
      hardware.fw-fanctrl = {
        enable = true;
        config.strategies = { };
      };
    })
  ];
}
