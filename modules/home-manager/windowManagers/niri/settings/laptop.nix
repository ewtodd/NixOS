{ ... }: {
  programs.niri.settings = {
    outputs = {
      "eDP-1" = {
        mode = "2256x1504";
        scale = 1.35;
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
    binds = {
      "Mod4+Shift+V" = {
        action = "output HDMI-A-2 mode 2560x1440 position -2560 0";
      };
    };
  };
  home.pointerCursor = { size = 48; };
}
