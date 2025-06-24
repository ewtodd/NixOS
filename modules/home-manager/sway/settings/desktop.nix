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

      # Workspace output assignments
      workspaceOutputAssign = [
        {
          workspace = "1";
          output = "HDMI-A-3";
        }
        {
          workspace = "2";
          output = "HDMI-A-3";
        }
        {
          workspace = "3";
          output = "HDMI-A-3";
        }
        {
          workspace = "4";
          output = "HDMI-A-3";
        }
        {
          workspace = "5";
          output = "HDMI-A-2";
        }
        {
          workspace = "6";
          output = "HDMI-A-2";
        }
      ];
    };
    extraConfig = ''
      exec . /etc/nixos/modules/home-manager/sway/scripts/startup-terminals.sh
    '';
  };

}
