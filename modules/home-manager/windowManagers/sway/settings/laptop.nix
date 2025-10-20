{ config, pkgs, ... }: {
  wayland.windowManager.sway = {
    config = {
      # Output configuration
      output = {
        "eDP-1" = {
          resolution = "2256x1504";
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
      extraConfig = ''
        # Thunderbird compose window
        for_window [app_id="thunderbird" title="^Write:"] floating enable, resize set 75 ppt 75 ppt, move position center

        # PulseAudio volume control
        for_window [title="Volume Control"] floating enable, resize set 75 ppt 75 ppt, move position center

        # Floating kitty terminal
        for_window [app_id="floatingkitty"] floating enable, resize set 75 ppt 75 ppt, move position center

        # Firefox file upload dialog
        for_window [app_id="firefox" title="File Upload"] floating enable, resize set 75 ppt 75 ppt, move position center

        # GEANT4 simulation window
        for_window [class="sim"] floating enable, resize set 75 ppt 75 ppt, move position center

        # ROOT plots 
        for_window [class="ROOT"] floating enable, resize set 75 ppt 75 ppt, move position center

        #GNOME disks 
        for_window [app_id="gnome-disks"] floating enable, resize set 75 ppt 75 ptt, move position center
      '';
    };
  };
  home.pointerCursor = { size = 48; };
}
