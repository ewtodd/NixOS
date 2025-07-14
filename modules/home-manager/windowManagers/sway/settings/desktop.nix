{ config, pkgs, ... }: {
  wayland.windowManager.sway = {
    enable = true;
    config = {
      # Output configuration
      output = {
        "HDMI-A-1" = {
          mode = "1920x1080@74.973Hz";
          position = "0,0";
        };
        "DP-3" = {
          resolution = "1920x1080";
          position = "-1920,0";
        };
      };
    };
  };

}
