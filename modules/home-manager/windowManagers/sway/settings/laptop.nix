{ config, pkgs, ... }: {
  wayland.windowManager.sway = {
    config = {
      # Output configuration
      output = {
        "eDP-1" = {
          resolution = "1920x1080";
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
