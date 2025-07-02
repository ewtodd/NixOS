{ config, ... }:

let colors = config.colorScheme.palette;
in {
  programs.niri.settings = {
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
