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

  };
}
