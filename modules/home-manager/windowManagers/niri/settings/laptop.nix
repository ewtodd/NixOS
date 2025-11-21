{ ... }: {
  xdg.configFile."niri/laptop.kdl".text = ''
    output "DP-3" {
        transform "normal"
        position x=-1920 y=0
        mode "1920x1080"
    }
    output "DP-4" {
        transform "normal"
        position x=-1920 y=0
        mode "1920x1080"
    }
    output "HDMI-A-2" {
        transform "normal"
        position x=-1920 y=0
        mode "1920x1080"
    }
    output "eDP-1" {
        scale 1.350000
        transform "normal"
        position x=0 y=0
        mode "2256x1504@47.998000"
    }
    window-rule {
        match app-id="firefox"
        default-column-width { proportion 0.750000; }
    }

    window-rule {
        match app-id="Slack"
        default-column-width { proportion 0.750000; }
    }
    window-rule {
        match app-id="thunderbird"
        default-column-width { proportion 0.750000; }
    }
  '';

  home.pointerCursor = { size = 48; };
}
