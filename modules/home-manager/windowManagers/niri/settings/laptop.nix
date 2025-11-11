{ ... }: {
  programs.niri.settings = {
    window-rules = [
      {
        matches = [{ app-id = "Slack"; }];
        default-column-width.proportion = 0.75;
      }
      {
        matches = [{ app-id = "thunderbird"; }];
        default-column-width.proportion = 0.75;
      }
    ];
    outputs = {
      "eDP-1" = {
        mode = {
          width = 2256;
          height = 1504;
          # Optional refresh rate can be added like refresh = 60;
        };
        scale = 1.35;
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
      "DP-4" = {
        mode = {
          width = 1920;
          height = 1080;
        };
        position = {
          x = -1920;
          y = 0;
        };
      };
      "DP-3" = {
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

  home.pointerCursor = { size = 48; };
}
