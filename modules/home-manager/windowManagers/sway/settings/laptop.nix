{ config, pkgs, ... }: {
  wayland.windowManager.sway = {
    config = {
      startup = [{ command = "blueman-applet"; }];
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

      # Workspace output assignments
      workspaceOutputAssign = [
        {
          workspace = "1";
          output = "eDP-1";
        }
        {
          workspace = "2";
          output = "eDP-1";
        }
        {
          workspace = "3";
          output = "eDP-1";
        }
        {
          workspace = "4";
          output = "eDP-1";
        }
        {
          workspace = "5";
          output = "HDMI-A-2";
        }
      ];

    };

  };
}
