{ config, lib, ... }:

with lib;

let colors = config.colorScheme.palette;
in {
  imports =
    [ ./opts.nix ./keymaps.nix ./plugins.nix ./performance.nix ./split.nix ];

  programs.nixvim = {
    colorschemes = {
      base16 = {
        enable = true;
        colorscheme = {
          base00 = "#${colors.base00}";
          base01 = "#${colors.base01}";
          base02 = "#${colors.base02}";
          base03 = "#${colors.base03}";
          base04 = "#${colors.base04}";
          base05 = "#${colors.base05}";
          base06 = "#${colors.base06}";
          base07 = "#${colors.base07}";
          base08 = "#${colors.base08}";
          base09 = "#${colors.base09}";
          base0A = "#${colors.base0A}";
          base0B = "#${colors.base0B}";
          base0C = "#${colors.base0C}";
          base0D = "#${colors.base0D}";
          base0E = "#${colors.base0E}";
          base0F = "#${colors.base0F}";
        };
        settings = { telescope_borders = true; };
      };
    };
  };

}
