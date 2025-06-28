{ config, lib, ... }:

let colors = config.colorScheme.palette;
in {
  wayland.windowManager.sway.config.colors = {
    focused = {
      border = "#${colors.base0D}";
      background = "#${colors.base0D}";
      text = "#${colors.base00}";
      indicator = "#${colors.base0D}";
      childBorder = "#${colors.base0D}";
    };
    focusedInactive = {
      border = "#${colors.base03}";
      background = "#${colors.base03}";
      text = "#${colors.base05}";
      indicator = "#${colors.base03}";
      childBorder = "#${colors.base03}";
    };
    unfocused = {
      border = "#${colors.base01}";
      background = "#${colors.base01}";
      text = "#${colors.base05}";
      indicator = "#${colors.base01}";
      childBorder = "#${colors.base01}";
    };
    urgent = {
      border = "#${colors.base03}";
      background = "#${colors.base08}";
      text = "#${colors.base00}";
      indicator = "#${colors.base08}";
      childBorder = "#${colors.base08}";
    };
  };
}
