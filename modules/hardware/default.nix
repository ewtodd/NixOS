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
        lm_sensors
      ];
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
      services.tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 70;

          CPU_BOOST_ON_BAT = 0;
          CPU_BOOST_ON_AC = 1;
        };
      };
      hardware.fw-fanctrl = {
        enable = true;
        config.strategies = { };
      };
    })
  ];
}
