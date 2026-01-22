{ inputs, ... }:
let
  inherit (inputs.niri-nix.lib) mkNiriKDL;

  desktopConfig = {
    output = [
      {
        _args = [ "DP-3" ];
        transform = "normal";
        position._props = {
          x = 0;
          y = 0;
        };
        mode = "3440x1440@180.000000";
        variable-refresh-rate._props = {
          on-demand = true;
        };
        focus-at-startup = [ ];
        layout = {
          default-column-width = {
            proportion = 0.33333;
          };
          preset-column-widths._children = [
            { proportion = 0.66667; }
            { proportion = 0.5; }
            { proportion = 0.33333; }
          ];
        };
      }
      {
        _args = [ "HDMI-A-5" ];
        transform = "normal";
        position._props = {
          x = 0;
          y = 0;
        };
        mode = "1920x1080@75.000";
      }
      {
        _args = [ "HDMI-A-1" ];
        transform = "normal";
        position._props = {
          x = -1920;
          y = 0;
        };
        mode = "1920x1080@74.973";
        layout = {
          default-column-width = {
            proportion = 0.75;
          };
        };
      }
      {
        _args = [ "DP-4" ];
        transform = "normal";
        position._props = {
          x = -1920;
          y = 0;
        };
        mode = "1920x1080@144.002";
      }
    ];
  };
in
{
  xdg.configFile."niri/desktop.kdl".text = mkNiriKDL desktopConfig;
}
