{ config, lib, pkgs, ... }:

{
  imports =
    [ ./opts.nix ./keymaps.nix ./plugins.nix ./performance.nix  ];

  config = let profile = config.Profile;
  in {
    programs.nixvim = {
      colorschemes = if (profile == "play") then {
        tokyonight = {
          enable = true;
          settings = {
            # Choose your preferred style: "night" (default), "storm", "moon", "day"
            style = "night";
            transparent = true;
            terminalColors = true;
            styles = {
              sidebars = "transparent";
              floats = "transparent";
            };

            # Optional: extra highlights for full transparency
            on_highlights = ''
              function(hl, c)
                -- Make UI elements transparent
                hl.Normal = { bg = "none" }
                hl.NormalNC = { bg = "none" }
                hl.NormalFloat = { bg = "none" }
                hl.FloatBorder = { bg = "none" }
                hl.Pmenu = { bg = "none" }
                hl.PmenuSbar = { bg = "none" }
                hl.PmenuThumb = { bg = "none" }
                hl.StatusLine = { bg = "none" }
                hl.StatusLineNC = { bg = "none" }
                hl.TabLine = { bg = "none" }
                hl.TabLineFill = { bg = "none" }
                hl.TabLineSel = { bg = "none" }
                hl.SignColumn = { bg = "none" }
                hl.VertSplit = { bg = "none" }
                hl.WinSeparator = { bg = "none" }
                hl.NonText = { bg = "none" }
                hl.EndOfBuffer = { bg = "none" }
                -- Telescope transparency (see [3])
                hl.TelescopeNormal = { bg = "none", fg = c.fg_dark }
                hl.TelescopeBorder = { bg = "none", fg = c.bg_dark }
              end
            '';
          };
        };
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
