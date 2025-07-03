{ config, pkgs, ... }: {
  wayland.windowManager.sway = {
    enable = true;
    config = {
      # Output configuration
      output = {
        "HDMI-A-3" = {
          mode = "1920x1080@74.973Hz";
          position = "0,0";
        };
        "HDMI-A-2" = {
          resolution = "1920x1080";
          position = "-1920,0";
        };
      };
    };
  };

}
