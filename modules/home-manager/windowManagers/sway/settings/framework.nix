{ config, pkgs, ... }: {
  wayland.windowManager.sway = {
    config = {
      # Output configuration
      output = {
        "eDP-1" = {
          resolution = "3000x2000";
          scale = "1.35";
          position = "0,0";
        };
        "HDMI-A-2" = {
          resolution = "1920x1080";
          position = "-1920,0";
        };
        "DP-4" = {
          resolution = "1920x1080";
          position = "-1920,0";
        };
        "DP-3" = {
          resolution = "1920x1080";
          position = "-1920,0";
        };

      };
      keybindings = {
        "Mod4+Shift+V" = "output HDMI-A-2 mode 2560x1440 position -2560 0";
      };
    };
  };
  home.pointerCursor = { size = 48; };
}
