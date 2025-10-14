{ lib, ... }:

with lib; {
  options = {

    DeviceType = mkOption {
      type = types.enum [ "server" "laptop" "desktop" ];
      default = "desktop";
      description = "Device type for hardware-specific configurations";
    };

    WindowManager = mkOption {
      type = types.enum [ "sway" "niri" ];
      default = "sway";
      description = "Window manager to use";
    };
  };
}
