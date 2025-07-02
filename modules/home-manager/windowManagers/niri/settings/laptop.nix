{ config, pkgs, ... }: {

  programs.niri.settings = {
    outputs = {
      "eDP-1" = {
        mode = {
          width = 1920;
          height = 1080;
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
    spawn-at-startup = [{ command = [ "blueman-applet" ]; }];
  };
}
