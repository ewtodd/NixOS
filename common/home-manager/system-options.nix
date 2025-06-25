{ lib, ... }:

with lib;

{
  options = {
    Profile = mkOption {
      type = types.enum [ "work" "play" ];
      default = "play";
      description = "Profile for user (work/play)";
    };

    DeviceType = mkOption {
      type = types.enum [ "laptop" "desktop" ];
      default = "desktop";
      description = "Device type for hardware-specific configurations";
    };

    WindowManager = mkOption {
      type = types.enum [ "sway" "hyprland" ];
      default = "sway";
      description = "Window manager to use";
    };
  };
}
