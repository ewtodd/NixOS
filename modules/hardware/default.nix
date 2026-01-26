{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  unstable = inputs.unstable.legacyPackages.${pkgs.system};
  cb-ucm-conf = pkgs.alsa-ucm-conf.overrideAttrs {
    wttsrc = pkgs.fetchurl {
      url = "https://github.com/WeirdTreeThing/chromebook-ucm-conf/archive/1328e46bfca6db2c609df9c68d37bb418e6fe279.tar.gz";
      hash = "sha256-eTP++vdS7cKtc8Mq4qCzzKtTRM/gsLme4PLkN0ZWveo=";
    };
    unpackPhase = ''
      runHook preUnpack
      tar xf "$src"
      tar xf "$wttsrc"
      runHook postUnpack
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/alsa
      cp -r alsa-ucm*/{ucm,ucm2} $out/share/alsa
      cp -r chromebook-ucm*/common $out/share/alsa/ucm2
      cp -r chromebook-ucm*/adl/* $out/share/alsa/ucm2/conf.d
      runHook postInstall
    '';
  };
in
{
  config = lib.mkMerge [
    (lib.mkIf (config.systemOptions.graphics.amd.enable) {
      hardware.graphics = {
        enable = true;
        package = pkgs.mesa;
        enable32Bit = true;
        extraPackages = with pkgs; [
          vulkan-tools
          rocmPackages.clr.icd
        ];
      };

      environment.systemPackages = with pkgs; [
        rocmPackages.rocminfo
        rocmPackages.rocm-smi
        btop-rocm
        lm_sensors
      ];
    })
    (lib.mkIf (config.systemOptions.graphics.intel.enable) {
      hardware.graphics = {
        enable = true;
        package = pkgs.mesa;
        enable32Bit = true;
        extraPackages = with pkgs; [
          vpl-gpu-rt
          intel-media-driver
          vulkan-tools
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [ intel-vaapi-driver ];
      };
      environment.systemPackages = with pkgs; [
        btop
        lm_sensors
      ];
    })
    (lib.mkIf (config.systemOptions.audio.chromebook.enable) {
      environment = {
        systemPackages = [ pkgs.sof-firmware ];
        sessionVariables.ALSA_CONFIG_UCM2 = "${cb-ucm-conf}/share/alsa/ucm2";
      };
      system.replaceDependencies.replacements = [
        {
          original = pkgs.alsa-ucm-conf;
          replacement = cb-ucm-conf;
        }
      ];
    })
    (lib.mkIf (config.systemOptions.hardware.suzyqable.enable) {
      environment.systemPackages = with pkgs; [
        openocd
        screen
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
      environment.systemPackages = with unstable; [ i2c-tools ];
      services.hardware.openrgb = {
        enable = true;
        motherboard = "intel";
        package = unstable.openrgb-with-all-plugins;
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

          START_CHARGE_THRESH_BAT0 = 20;
          STOP_CHARGE_THRESH_BAT0 = 90;
        };
      };
      hardware.fw-fanctrl = {
        enable = true;
        config.strategies = { };
      };
    })
  ];
}
