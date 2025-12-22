{ lib, ... }:

with lib; {
  options = {

    DeviceType = mkOption {
      type = types.enum [ "server" "laptop" "desktop" ];
      default = "desktop";
      description = "Device type for hardware-specific configurations";
    };

    CornerRadius = mkOption {
      type = types.int;
      default = 10;
      description = "Corner radius for all windows.";
    };
  };
}
