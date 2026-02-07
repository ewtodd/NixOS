{ lib, ... }:
with lib;
{
  options = {
    systemOptions = {
      # Graphics options (NixOS only)
      graphics.amd.enable = mkEnableOption "AMD graphics";
      graphics.intel.enable = mkEnableOption "Intel graphics";

      # Audio options (NixOS only)
      audio.chromebook.enable = mkEnableOption "Chromebook audio fixes";

      # Hardware options (NixOS only)
      hardware.suzyqable.enable = mkEnableOption "Suzyqable chromebook debugging support";
      hardware.fingerprint.enable = mkEnableOption "Fprintd support";
      hardware.openRGB.enable = mkEnableOption "openRGB support";

      # Device type options (cross-platform)
      deviceType.laptop.enable = mkEnableOption "Laptop-specific features";
      deviceType.desktop.enable = mkEnableOption "Desktop-specific features";

      # Application options (cross-platform where applicable)
      apps.zoom.enable = mkEnableOption "Zoom";
      apps.remarkable.enable = mkEnableOption "Remarkable from wrapWine flake";
      apps.quickemu.enable = mkEnableOption "Quickemu";

      # Service options
      services.ssh.enable = mkEnableOption "SSH with non-standard port";
      services.suspend-then-hibernate.enable = mkEnableOption "Suspend then hibernate.";
      services.tailscale.enable = mkEnableOption "Literally just tailscale...";
      services.ai.enable = mkEnableOption "Local AI.";

      # Security options (NixOS only)
      security.harden.enable = mkEnableOption "Try to reasonably harden NixOS.";

      # Owner identification (cross-platform)
      owner.e.enable = mkEnableOption "Whether this is an e-device. If it isn't then it must be a v-device!";

      # NixOS VMs on Darwin (Darwin only)
      nixos-vms.enable = mkEnableOption "Declarative NixOS Lima VMs on Darwin";
      nixos-vms.work.enable = mkEnableOption "Work VM";
      nixos-vms.work.autoStart = mkOption {
        type = types.bool;
        default = true;
        description = "Auto-start work VM on boot";
      };
      nixos-vms.play.enable = mkEnableOption "Play VM";
      nixos-vms.play.autoStart = mkOption {
        type = types.bool;
        default = false;
        description = "Auto-start play VM on boot";
      };
    };
  };
}
