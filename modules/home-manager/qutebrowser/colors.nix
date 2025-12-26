{ config, ... }:
let
  colors = config.colorScheme.palette;
in
{
  programs.qutebrowser.settings = {
    colors = {
      webpage = {
        preferred_color_scheme = "dark";
      };

      completion = {
        fg = "#${colors.base05}";
        odd.bg = "#${colors.base01}";
        even.bg = "#${colors.base00}";
        category = {
          fg = "#${colors.base0A}";
          bg = "#${colors.base00}";
          border = {
            top = "#${colors.base00}";
            bottom = "#${colors.base00}";
          };
        };
        item.selected = {
          fg = "#${colors.base05}";
          bg = "#${colors.base02}";
          border = {
            top = "#${colors.base02}";
            bottom = "#${colors.base02}";
          };
          match.fg = "#${colors.base0B}";
        };
        match.fg = "#${colors.base0B}";
        scrollbar = {
          fg = "#${colors.base05}";
          bg = "#${colors.base00}";
        };
      };

      contextmenu = {
        disabled = {
          bg = "#${colors.base01}";
          fg = "#${colors.base04}";
        };
        menu = {
          bg = "#${colors.base00}";
          fg = "#${colors.base05}";
        };
        selected = {
          bg = "#${colors.base02}";
          fg = "#${colors.base05}";
        };
      };

      downloads = {
        bar.bg = "#${colors.base00}";
        start = {
          fg = "#${colors.base00}";
          bg = "#${colors.base0D}";
        };
        stop = {
          fg = "#${colors.base00}";
          bg = "#${colors.base0C}";
        };
        error.fg = "#${colors.base08}";
      };

      hints = {
        fg = "#${colors.base00}";
        bg = "#${colors.base0A}";
        match.fg = "#${colors.base05}";
      };

      keyhint = {
        fg = "#${colors.base05}";
        suffix.fg = "#${colors.base05}";
        bg = "#${colors.base00}";
      };

      messages = {
        error = {
          fg = "#${colors.base00}";
          bg = "#${colors.base08}";
          border = "#${colors.base08}";
        };
        warning = {
          fg = "#${colors.base00}";
          bg = "#${colors.base0E}";
          border = "#${colors.base0E}";
        };
        info = {
          fg = "#${colors.base05}";
          bg = "#${colors.base00}";
          border = "#${colors.base00}";
        };
      };

      prompts = {
        fg = "#${colors.base05}";
        border = "#${colors.base00}";
        bg = "#${colors.base00}";
        selected = {
          bg = "#${colors.base02}";
          fg = "#${colors.base05}";
        };
      };

      statusbar = {
        normal = {
          fg = "#${colors.base0B}";
          bg = "#${colors.base00}";
        };
        insert = {
          fg = "#${colors.base00}";
          bg = "#${colors.base0D}";
        };
        passthrough = {
          fg = "#${colors.base00}";
          bg = "#${colors.base0C}";
        };
        private = {
          fg = "#${colors.base00}";
          bg = "#${colors.base01}";
        };
        command = {
          fg = "#${colors.base05}";
          bg = "#${colors.base00}";
          private = {
            fg = "#${colors.base05}";
            bg = "#${colors.base00}";
          };
        };
        caret = {
          fg = "#${colors.base00}";
          bg = "#${colors.base0E}";
          selection = {
            fg = "#${colors.base00}";
            bg = "#${colors.base0D}";
          };
        };
        progress.bg = "#${colors.base0D}";
        url = {
          fg = "#${colors.base05}";
          error.fg = "#${colors.base08}";
          hover.fg = "#${colors.base05}";
          success = {
            http.fg = "#${colors.base0C}";
            https.fg = "#${colors.base0B}";
          };
          warn.fg = "#${colors.base0E}";
        };
      };

      tabs = {
        bar.bg = "#${colors.base00}";
        indicator = {
          start = "#${colors.base0D}";
          stop = "#${colors.base0C}";
          error = "#${colors.base08}";
        };
        odd = {
          fg = "#${colors.base05}";
          bg = "#${colors.base01}";
        };
        even = {
          fg = "#${colors.base05}";
          bg = "#${colors.base00}";
        };
        pinned = {
          even = {
            bg = "#${colors.base0C}";
            fg = "#${colors.base07}";
          };
          odd = {
            bg = "#${colors.base0B}";
            fg = "#${colors.base07}";
          };
          selected = {
            even = {
              bg = "#${colors.base02}";
              fg = "#${colors.base05}";
            };
            odd = {
              bg = "#${colors.base02}";
              fg = "#${colors.base05}";
            };
          };
        };
        selected = {
          odd = {
            fg = "#${colors.base05}";
            bg = "#${colors.base02}";
          };
          even = {
            fg = "#${colors.base05}";
            bg = "#${colors.base02}";
          };
        };
      };
    };

  };
}
