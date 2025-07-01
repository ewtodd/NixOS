{ config, pkgs, lib, inputs, ... }: {
  programs.nixvim.extraPlugins = with pkgs.vimPlugins; [ plenary-nvim ];

  programs.nixvim.plugins = {
    web-devicons = { enable = true; };
    lualine = { enable = true; };

    telescope = {
      enable = true;
      extensions.file-browser.enable = true;

    };

    zk = {
      enable = true;
      settings = {
        picker = "telescope";
        lsp = { auto_attach.enabled = false; };
      };
    };

    render-markdown = {
      enable = true;
      settings = {
        file_types = [ "markdown" ];
        render_modes = true;
        # Remove image icons
        link = {
          enabled = true;
          image = ""; # No image icon
          email = "󰀓 ";
          hyperlink = "󰌹 ";
        };

        # Clean bullets
        bullet = {
          icons = [ "●" "○" "◆" "◇" ];
          highlight = "Normal";
        };
      };
    };

    wilder = { enable = true; };

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
    molten = {
      enable = true;
      settings = {
        auto_open_output = true;
        image_provider = "image.nvim";
        wrap_output = true;
        virt_text_output = true;
        virt_lines_off_by_1 = true;
        output_show_more = true;
        cell_marker = "# %%";
      };
    };

    image = {
      enable = true;
      settings = {
        backend = "kitty";
        only_render_image_at_cursor = true;
        only_render_image_at_cursor_mode = "popup";
        window_overlap_clear_enabled = true;
        window_overlap_clear_ft_ignore = [ "cmp_menu" "cmp_docs" "" ];
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
      grammarPackages = (with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        vim
        nix
        python
        cpp
        c
        bash
        yaml
        cmake
        markdown
      ]);
    };

    nix.enable = true;

    vimtex = {
      enable = true;
      settings = {
        view_method = "zathura";
        quickfix_open_on_warning = 0;
        compiler_callback_hooks = { };
      };
      texlivePackage = null;
    };

    lsp = {
      enable = true;
      servers = {
        clangd.enable = true;
        nixd.enable = true;
        pylsp.enable = true;
        yamlls.enable = true;
        bashls.enable = true;
        texlab.enable = true;
        cmake.enable = true;
        jsonls.enable = true;
        zk = {
          enable = true;
          rootMarkers = [ ".zk" ];
        };
      };
    };

    lsp-format = { enable = true; };

    none-ls = {
      enable = true;
      enableLspFormat = true;
      sources.formatting.nixfmt.enable = true;
      sources.formatting.black.enable = true;
      sources.formatting.bibclean.enable = true;
      sources.formatting.cmake_format.enable = true;
      sources.formatting.biome.enable = true;
    };

    illuminate = { enable = true; };

    luasnip = { enable = true; };

    cmp = {
      enable = true;
      settings = {
        performance = {
          debounce = 60;
          fetchingTimeout = 200;
          maxViewEntries = 30;
        };
        formatting = { fields = [ "kind" "abbr" "menu" ]; };
        sources = [
          { name = "zk"; }
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
        snippet = { expand = "luasnip"; };
        mapping = {
          "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          "<A-j>" = "cmp.mapping.select_next_item()";
          "<A-k>" = "cmp.mapping.select_prev_item()";
          "<A-e>" = "cmp.mapping.abort()";
          "<A-b>" = "cmp.mapping.scroll_docs(-4)";
          "<A-f>" = "cmp.mapping.scroll_docs(4)";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<A-CR>" =
            "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
        };
      };
    };

    cmp-nvim-lsp.enable = true;
    cmp-buffer.enable = true;
    cmp_luasnip.enable = true;
    cmp-cmdline.enable = true;
    indent-blankline = { enable = true; };

  };
}
