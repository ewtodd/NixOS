{ config, pkgs, ... }: {

  programs.niri.settings = {
    # Output configuration
    outputs = {
      "HDMI-A-3" = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 74.973;
        };
        position = {
          x = 0;
          y = 0;
        };
      };

      "HDMI-A-2" = {
        mode = {
          width = 1920;
          height = 1080;
        };
        position = {
          x = -1920;
          y = 0;
        };
      };
    };

    # Workspace assignments to outputs
    workspaces = {
      "1" = { open-on-output = "HDMI-A-3"; };
      "2" = { open-on-output = "HDMI-A-3"; };
      "3" = { open-on-output = "HDMI-A-3"; };
      "4" = { open-on-output = "HDMI-A-3"; };
      "5" = { open-on-output = "HDMI-A-2"; };
    };

  };
}
