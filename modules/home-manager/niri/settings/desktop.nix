{ ... }:
{
  xdg.configFile."niri/desktop.kdl".text = ''
    output "DP-3" {
        transform "normal"
        position x=0 y=0
        mode "3440x1440@180.000000"
        variable-refresh-rate on-demand=true
        focus-at-startup
        layout {
          default-column-width { proportion 0.33333; }
          preset-column-widths {
            proportion 0.66667
            proportion 0.5
            proportion 0.33333
          }
        }
    }
    output "HDMI-A-1" {
        transform "normal"
        position x=-1920 y=0
        mode "1920x1080@120.002"
    }
    output "HDMI-A-5" {
        transform "normal"
        position x=0 y=0
        mode "1920x1080@75.000"
    }
  '';
}
