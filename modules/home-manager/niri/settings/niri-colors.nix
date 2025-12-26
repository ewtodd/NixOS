{ config, ... }:

let
  colors = config.colorScheme.palette;
in
{
  programs.niri.settings = {
    layer-rules = [
      {
        matches = [ { namespace = "wallpaper"; } ];
        place-within-backdrop = true;
      }
    ];

    overview = {
      workspace-shadow.color = "#${colors.base00}99";
    };
    layout = {
      background-color = "transparent";
      focus-ring = {
        enable = true;
        width = 3;
        inactive.color = "#${colors.base03}";
        active.gradient = {
          from = "#${colors.base0D}";
          to = "#${colors.base0E}";
          angle = 180;
        };
      };
    };
  };
}
