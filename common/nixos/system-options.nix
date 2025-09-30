{ lib, ... }:

with lib; {
  options = {

    DeviceType = mkOption {
      type = types.enum [ "laptop" "framework" "desktop" ];
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
