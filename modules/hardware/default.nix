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
      services.tuned = {
        enable = true;
      };
    })
    (lib.mkIf (config.systemOptions.hardware.framework.enable) {
      hardware.fw-fanctrl = {
        enable = true;
        config.strategies = { };
      };
    })
    (lib.mkIf (config.systemOptions.hardware.twoinone.enable) {
      hardware.sensor.iio.enable = true;
      services.iio-niri = {
        enable = true;
        extraArgs = [
          "--monitor"
          "eDP-1"
        ];
      };
      environment.systemPackages = with pkgs; [ xournalpp ];
    })
  ];
}
