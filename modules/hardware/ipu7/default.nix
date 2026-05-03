{
  config,
  lib,
  pkgs,
  ...
}:
# TODO: Remove this whole module once nixpkgs PR #479283 (ipu7: init) lands.
# https://github.com/NixOS/nixpkgs/pull/479283
# At that point, replace with `hardware.ipu7.enable = true;` against the
# upstream module and drop ./pkgs.
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;

  cfg = config.hardware.ipu7;

  ipu7Overlay = final: prev: {
    ipu7-camera-bins = final.callPackage ./pkgs/ipu7-camera-bins/package.nix { };

    ipu7x-camera-hal = final.callPackage ./pkgs/ipu7-camera-hal {
      ipuVersion = "ipu7x";
    };
    ipu75xa-camera-hal = final.callPackage ./pkgs/ipu7-camera-hal {
      ipuVersion = "ipu75xa";
    };

    gst_all_1 = prev.gst_all_1.overrideScope (
      finalGst: _: {
        icamerasrc-ipu7x = finalGst.callPackage ./pkgs/icamerasrc {
          ipu7-camera-hal = final.ipu7x-camera-hal;
        };
        icamerasrc-ipu75xa = finalGst.callPackage ./pkgs/icamerasrc {
          ipu7-camera-hal = final.ipu75xa-camera-hal;
        };
      }
    );
  };
in
{

  options.hardware.ipu7 = {

    enable = mkEnableOption "support for Intel IPU7/MIPI cameras";

    platform = mkOption {
      type = types.enum [
        "ipu7x"
        "ipu75xa"
      ];
      description = ''
        Choose the version for your hardware platform.

        - ipu7x (Lunar Lake)
        - ipu75xa (Lunar Lake)
      '';
    };

  };

  config = mkIf cfg.enable {

    nixpkgs.overlays = [ ipu7Overlay ];

    boot.extraModulePackages = [
      (config.boot.kernelPackages.callPackage ./pkgs/ipu7-drivers { })
    ];

    hardware.firmware = with pkgs; [
      ipu7-camera-bins
      ivsc-firmware
    ];

    services.udev.extraRules = ''
      SUBSYSTEM=="intel-ipu7-psys", MODE="0660", GROUP="video"
    '';

    services.v4l2-relayd.instances.ipu7 = {
      enable = mkDefault true;

      cardLabel = mkDefault "Intel MIPI Camera";

      extraPackages =
        with pkgs.gst_all_1;
        [ ]
        ++ optional (cfg.platform == "ipu7x") icamerasrc-ipu7x
        ++ optional (cfg.platform == "ipu75xa") icamerasrc-ipu75xa;

      input = {
        pipeline = "icamerasrc";
        format = "NV12";
      };
    };
  };
}
