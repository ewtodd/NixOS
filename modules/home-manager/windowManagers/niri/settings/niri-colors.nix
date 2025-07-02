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
    overview = {
      backdrop-color = "#${colors.base03}";
      workspace-shadow.color = "#${colors.base00}99";
    };
    layout = {
      focus-ring = {
        enable = true;
        width = 2;
        active.color = "#${colors.base0D}";
        inactive.color = "#${colors.base03}";
        urgent.color = "#${colors.base08}";
      };
      shadow = {
        enable = true;
        color = "#${colors.base00}99";
        inactive-color = "#${colors.base00}55";
      };
    };
  };
}
