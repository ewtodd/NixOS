{ inputs, ... }:
let
  inherit (inputs.niri-nix.lib) mkNiriKDL;
  laptopConfig = {
    layout = {
      default-column-width = {
        proportion = 0.75;
      };
      preset-column-widths._children = [
        { proportion = 0.5; }
        { proportion = 0.75; }
      ];
    };
    output = [
      {
        _args = [ "DP-3" ];
        transform = "normal";
        position._props = {
          x = -1920;
          y = 0;
        };
        mode = "1920x1080";
      }
      {
        _args = [ "DP-4" ];
        transform = "normal";
        position._props = {
          x = -1920;
          y = 0;
        };
        mode = "1920x1080";
      }
      {
        _args = [ "HDMI-A-2" ];
        transform = "normal";
        position._props = {
          x = -1920;
          y = 0;
        };
        mode = "1920x1080";
      }
      {
        _args = [ "eDP-1" ];
        scale = 1.35;
        transform = "normal";
        position._props = {
          x = 0;
          y = 0;
        };
        mode = "2256x1504@47.998000";
      }
    ];
  };
in
{
  xdg.configFile."niri/laptop.kdl".text = mkNiriKDL laptopConfig;

  home.pointerCursor = {
    size = 48;
  };
}
