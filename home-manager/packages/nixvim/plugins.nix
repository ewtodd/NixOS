{
  pkgs,
  ...
}:
{

  extraConfigLua = ''
    vim.o.splitbelow = false
    vim.o.splitright = false
  '';

  extraPlugins = [ pkgs.vimPlugins.plenary-nvim ];

  plugins = {
    web-devicons = {
      enable = true;
    };

    lualine = {
      enable = true;
    };

    telescope = {
      enable = true;
      extensions.file-browser.enable = true;
    };

    undotree = {
      enable = true;
      settings = {
        WindowLayout = 3;
        SetFocusWhenToggle = true;
        ShortIndicators = true;
        DiffAutoOpen = true;
        DiffpanelHeight = 10;
        SplitWidth = 35;
        RelativeTimestamp = true;
        CursorLine = true;
        HelpLine = false;
      };
    };

    which-key = {
      enable = true;
      settings = {
        icons = {
          keys = {
            Up = "";
            Down = "";
            Left = "";
            Right = "";
            C = "CTRL ";
            M = "ALT ";
            D = "SUPER ";
            S = "SHIFT ";
            CR = "ENTER";
            Esc = "ESC ";
            ScrollWheelDown = "SCROLL DOWN ";
            ScrollWheelUp = "SCROLL UP ";
            NL = "NEW LINE ";
            BS = "󰁮";
            Space = "SPACE ";
            Tab = "TAB ";
            F1 = "󱊫";
            F2 = "󱊬";
            F3 = "󱊭";
            F4 = "󱊮";
            F5 = "󱊯";
            F6 = "󱊰";
            F7 = "󱊱";
            F8 = "󱊲";
            F9 = "󱊳";
            F10 = "󱊴";
            F11 = "󱊵";
            F12 = "󱊶";
          };
        };
      };
    };

    image = {
      enable = true;
      settings = {
        backend = "kitty";
        only_render_image_at_cursor = true;
        only_render_image_at_cursor_mode = "popup";
        window_overlap_clear_enabled = true;
        window_overlap_clear_ft_ignore = [
          "cmp_menu"
          "cmp_docs"
          ""
        ];
      };
    };

    barbar = {
      enable = true;
      settings = {
        clickable = true;
        focus_on_close = "left";
        insert_at_end = true;
      };
    };

    orgmode = {
      enable = true;
      settings = {
        win_split_mode = "tabnew";
        org_agenda_files = "~/org/**/*";
        org_default_notes_file = "~/org/refile.org";
        org_capture_templates = {
          t = {
            description = "Todo";
            template = "* TODO %?\n  DEADLINE: %t";
            target = "~/org/refile.org";
          };
          n = {
            description = "Note";
            template = "* %?\n  %U";
            target = "~/org/refile.org";
          };
        };
      };
    };

    treesitter = {
      enable = true;
      nixvimInjections = true;
      settings.highlight.enable = true;
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        c
        cpp
        rust
        nix
        python
        yaml
        bash
        latex
        bibtex
        cmake
        json
        lua
        toml
        markdown
        markdown_inline
      ];
    };

    nix.enable = true;

    vimtex = {
      enable = true;
      settings = {
        view_method = "zathura";
        quickfix_open_on_warning = 0;
        compiler_callback_hooks = { };
        quickfix_autoclose_after_keystrokes = 1;
        syntax_conceal_disable = true;
      };
      texlivePackage = null;
    };

    lsp = {
      enable = true;
      servers = {
        dockerls.enable = false;
        clangd = {
          enable = true;
        };
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };
        nixd.enable = true;
        pylsp.enable = true;
        yamlls.enable = true;
        bashls.enable = true;
        texlab.enable = true;
        cmake.enable = true;
        jsonls.enable = true;
      };
    };

    conform-nvim = {
      enable = true;
      autoInstall.enable = true;
      settings = {
        format_on_save = {
          timeout_ms = 500;
          lsp_format = "fallback";
        };
        formatters_by_ft = {
          nix = [ "nixfmt" ];
          python = [ "yapf" ];
          bib = [ "bibclean" ];
          cmake = [ "cmake_format" ];
          c = [ "clang_format" ];
          cpp = [ "clang_format" ];
        };
        formatters = {
          clang_format = {
            prepend_args = [ "--style={BasedOnStyle: LLVM, BreakStringLiterals: false}" ];
          };
        };
      };
    };

    illuminate = {
      enable = true;
    };

    luasnip = {
      enable = true;
    };

    cmp = {
      enable = true;
      settings = {
        performance = {
          debounce = 60;
          fetchingTimeout = 200;
          maxViewEntries = 30;
        };
        formatting = {
          fields = [
            "kind"
            "abbr"
            "menu"
          ];
        };
        sources = [
          { name = "nvim_lsp"; }
          {
            name = "buffer";
            option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
            keywordLength = 3;
          }
          {
            name = "path";
            keywordLength = 3;
          }
          {
            name = "luasnip";
            keywordLength = 3;
          }
        ];
        snippet = {
          expand = "luasnip";
        };
        mapping = {
          "<Tab>" = ''
            cmp.mapping(function(fallback)
              local luasnip = require("luasnip")
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_locally_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, {'i', 's'})
          '';

          "<S-Tab>" = ''
            cmp.mapping(function(fallback)
              local luasnip = require("luasnip")
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, {'i', 's'})
          '';

          "<A-j>" = "cmp.mapping.select_next_item()";
          "<A-k>" = "cmp.mapping.select_prev_item()";
          "<A-e>" = "cmp.mapping.abort()";
          "<A-b>" = "cmp.mapping.scroll_docs(-4)";
          "<A-f>" = "cmp.mapping.scroll_docs(4)";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<A-CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
        };
      };
    };

    cmp-nvim-lsp.enable = true;
    cmp-buffer.enable = true;
    cmp_luasnip.enable = true;
    cmp-cmdline.enable = true;
    indent-blankline = {
      enable = true;
    };

    snacks = {
      enable = true;
      settings = {
        input.enabled = true;
        picker.enabled = true;
        terminal = {
          enabled = true;
          win = {
            position = "right";
          };
        };
      };
    };
  };
}
