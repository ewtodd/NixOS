{ config, pkgs, ... }: {
  wayland.windowManager.sway = {
    enable = true;
    config = {
      # Output configuration
      output = {
        "HDMI-A-1" = {
          mode = "1920x1080@74.973Hz";
          position = "-1920,0";
        };
        "DP-3" = {
          resolution = "3440x1440@180.000Hz";
          position = "0,0";
        };
      };
    };
  };

}
