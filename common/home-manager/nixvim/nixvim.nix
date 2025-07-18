{ config, lib, pkgs, ... }:

{
  imports =
    [ ./opts.nix ./keymaps.nix ./plugins.nix ./performance.nix ./split.nix ];

  config = let profile = config.Profile;
  in {
    programs.nixvim = {
      colorschemes = if (profile == "play") then {
        rose-pine = { enable = true; };
      } else {

        kanagawa = {
          enable = true;
          settings = {
            # Enable transparency
            transparent = true;

            # Disable background for inactive windows
            dimInactive = false;

            # Enable terminal colors
            terminalColors = true;

            # Choose theme variant (wave is default, dragon and lotus are alternatives)
            theme = "wave";

            # Enable undercurls for better terminal support
            undercurl = true;

            # Style configurations
            commentStyle = { italic = true; };

            functionStyle = { };

            keywordStyle = { italic = true; };

            statementStyle = { bold = true; };

            typeStyle = { };

            # Color overrides for transparency
            colors = {
              theme = {
                all = {
                  ui = {
                    bg_gutter = "none";
                    bg_statusline = "none";
                    bg_tabline = "none";
                    bg_float = "none";
                  };
                };
              };
            };

            # Additional highlight overrides for complete transparency
            overrides = ''
              function(colors)
                return {
                  Normal = { bg = "none" },
                  NormalFloat = { bg = "none" },
                  FloatBorder = { bg = "none" },
                  Pmenu = { bg = "none" },
                  PmenuSbar = { bg = "none" },
                  PmenuThumb = { bg = "none" },
                  StatusLine = { bg = "none" },
                  StatusLineNC = { bg = "none" },
                  TabLine = { bg = "none" },
                  TabLineFill = { bg = "none" },
                  TabLineSel = { bg = "none" },
                  SignColumn = { bg = "none" },
                  VertSplit = { bg = "none" },
                  WinSeparator = { bg = "none" },
                }
              end
            '';
          };
        };
      };
    };
  };
}
