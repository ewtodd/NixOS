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

      border = {
        enable = true;
        width = 2;
        active.color = "#${colors.base0D}";
        inactive.color = "#${colors.base01}";
        urgent.color = "#${colors.base08}";
      };
    };
  };
}
