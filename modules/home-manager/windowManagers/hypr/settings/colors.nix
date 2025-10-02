{ config, ... }:
let colors = config.colorScheme.palette;
in {
  wayland.windowManager.hyprland = {
    settings = {
      general = {
        "col.active_border" =
          "rgba(${colors.base0D}ee) rgba(${colors.base0E}ee) 45deg";
        "col.inactive_border" = "rgba(${colors.base01}aa)";
      };

      # Decoration settings with nix-colors
      decoration = { shadow = { color = "rgba(${colors.base00}ee)"; }; };

      # Group colors (for window grouping)
      group = {
        "col.border_active" = "rgba(${colors.base0D}ee)";
        "col.border_inactive" = "rgba(${colors.base01}aa)";
        "col.border_locked_active" = "rgba(${colors.base08}ee)";
        "col.border_locked_inactive" = "rgba(${colors.base03}aa)";
      };

      # Misc settings with colors
      misc = { background_color = "rgba(${colors.base00}ff)"; };
    };
  };
}
