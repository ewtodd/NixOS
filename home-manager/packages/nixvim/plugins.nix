{
  pkgs,
  config,
  ...
}:
{

  extraConfigLua = ''
    vim.o.splitbelow = false
    vim.o.splitright = false
    vim.o.autoread = true
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

    tiny-inline-diagnostic = {
      enable = true;
      settings = {
        preset = "simple";
      };
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

    treesitter = {
      enable = true;
      nixvimInjections = true;
      settings.highlight.enable = true;
      grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
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
        typescript
        tsx
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
        ts_ls = {
          enable = true;
          settings = {
            preferences = {
              includeCompletionsForModuleExports = true;
              includeCompletionsWithSnippetText = true;
            };
          };
        };
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
          toml = [ "taplo" ];
          typescript = [ "biome" ];
          typescriptreact = [ "biome" ];
          javascript = [ "biome" ];
          javascriptreact = [ "biome" ];
        };
        formatters = {
          clang_format = {
            prepend_args = [ "--style={BasedOnStyle: LLVM, BreakStringLiterals: false}" ];
          };
          biome = {
            command = "${pkgs.biome}/bin/biome";
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

    friendly-snippets = {
      enable = true;
    };

    blink-cmp = {
      enable = true;
      setupLspCapabilities = true;
      settings = {
        keymap = {
          preset = "default";
          "<Tab>" = [
            "select_next"
            "snippet_forward"
            "fallback"
          ];
          "<S-Tab>" = [
            "select_prev"
            "snippet_backward"
            "fallback"
          ];
          "<CR>" = [
            "accept"
            "fallback"
          ];
        };

        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];

          per_filetype = {
            tex = [
              "snippets"
              "path"
              "lsp"
              "buffer"
            ];

            plaintex = [
              "snippets"
              "path"
              "lsp"
              "buffer"
            ];
          };

          providers = {
            snippets = {
              score_offset = 10;
            };
            buffer = {
              score_offset = -7;
            };
          };
        };

        snippets = {
          expand.__raw = ''
            function(snippet)
              require("luasnip").lsp_expand(snippet)
            end
          '';

          active.__raw = ''
            function(filter)
              local luasnip = require("luasnip")

              if filter and filter.direction then
                return luasnip.jumpable(filter.direction)
              end

              return luasnip.in_snippet()
            end
          '';

          jump.__raw = ''
            function(direction)
              require("luasnip").jump(direction)
            end
          '';
        };
        completion = {
          list = {
            max_items = 30;
            selection = {
              preselect = true;
              auto_insert = false;
            };
          };
          documentation = {
            auto_show = true;
            auto_show_delay_ms = 300;
          };

          accept = {
            auto_brackets = {
              enabled = true;
              semantic_token_resolution = {
                enabled = false;
              };
            };
          };
          menu = {
            auto_show = true;
            max_height = 10;
          };

          ghost_text = {
            enabled = false;
          };
        };

        signature = {
          enabled = true;
        };
      };
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

    hex = {
      enable = true;
    };
  };
}
