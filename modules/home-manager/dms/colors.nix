{ config, ... }:
let colors = config.colorScheme.palette;
in {
  xdg.configFile."DankMaterialShell/colors.json".text = builtins.toJSON {
    dark = {
      name = "Eris Dark";
      primary = "#${colors.base0E}";
      primaryText = "#${colors.base00}";
      primaryContainer = "#${colors.base0D}";
      secondary = "#${colors.base08}";
      surface = "#${colors.base00}";
      surfaceText = "#${colors.base05}";
      surfaceVariant = "#${colors.base01}";
      surfaceVariantText = "#${colors.base05}";
      surfaceTint = "#${colors.base0E}";
      background = "#${colors.base00}";
      backgroundText = "#${colors.base05}";
      outline = "#${colors.base04}";
      surfaceContainer = "#${colors.base01}";
      surfaceContainerHigh = "#${colors.base02}";
      surfaceContainerHighest = "#${colors.base03}";
      error = "#${colors.base08}";
      warning = "#${colors.base0A}";
      info = "#${colors.base0C}";
      matugen_type = "scheme-fidelity";
    };
    light = {
      name = "Eris Dark";
      primary = "#${colors.base0E}";
      primaryText = "#${colors.base00}";
      primaryContainer = "#${colors.base0D}";
      secondary = "#${colors.base08}";
      surface = "#${colors.base00}";
      surfaceText = "#${colors.base05}";
      surfaceVariant = "#${colors.base01}";
      surfaceVariantText = "#${colors.base05}";
      surfaceTint = "#${colors.base0E}";
      background = "#${colors.base00}";
      backgroundText = "#${colors.base05}";
      outline = "#${colors.base04}";
      surfaceContainer = "#${colors.base01}";
      surfaceContainerHigh = "#${colors.base02}";
      surfaceContainerHighest = "#${colors.base03}";
      error = "#${colors.base08}";
      warning = "#${colors.base0A}";
      info = "#${colors.base0C}";
      matugen_type = "scheme-fidelity";
    };
  };
}

