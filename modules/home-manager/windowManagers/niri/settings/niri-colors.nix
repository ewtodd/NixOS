{ config, ... }:

let colors = config.colorScheme.palette;
in {
  programs.niri.settings = {
    window-rules = [{
      matches = [ { } ]; # Match all windows
      excludes = [{ is-focused = true; }];
      shadow = {
        enable = true;
        draw-behind-window = false;
        inactive-color = "#${colors.base03}";
      };
    }];
    layer-rules = [{
      matches = [{ namespace = "wallpaper"; }];
      place-within-backdrop = true;
    }];

    overview = { workspace-shadow.color = "#${colors.base00}99"; };
    layout = {
      background-color = "transparent";
      focus-ring = {
        enable = true;
        width = 3;
        active.gradient = {
          from = "#${colors.base0D}";
          to = "#${colors.base0E}";
          angle = 180;
        };
      };
    };
  };
}
