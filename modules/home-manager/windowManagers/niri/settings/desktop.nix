{ ... }: {
  programs.niri.settings = {
    outputs = {
      "HDMI-A-1" = {
        mode = "1920x1080@74.973Hz";
        position = "-1920,0";
      };
      "DP-3" = {
        resolution = "3440x1440@180.000Hz";
        position = "0,0";
      };
    };
    binds = {
      "Mod4+Shift+V" = {
        action = "output HDMI-A-1 transform 90 position -1080 0";
      };
    };
  };
}
