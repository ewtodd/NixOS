{ ... }: {
  programs.niri.settings = {
    outputs = {
      "HDMI-A-1" = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 75.973;
        };
        position = {
          x = -1920;
          y = 0;
        };
      };
      "DP-3" = {
        mode = {
          width = 3440;
          height = 1440;
          refresh = 180.0;
        };
        position = {
          x = 0;
          y = 0;
        };
      };
    };
  };
}
