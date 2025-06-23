{ config, pkgs, lib, inputs, ... }: {
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.plenary-nvim ];
  programs.nixvim.plugins = {
    web-devicons = { enable = true; };
    lualine = { enable = true; };

    telescope = {
      enable = true;
      extensions.file-browser.enable = true;
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
      grammarPackages = [
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.vim
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.java
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.latex
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.nix
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.python
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.cpp
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.c
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.bash
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.yaml
        pkgs.vimPlugins.nvim-treesitter.builtGrammars.cmake
      ];
    };

    nix.enable = true;

    vimtex = {
      enable = true;
      settings = { view_general_viewer = "fancy-cat"; };
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
          "<C-j>" = "cmp.mapping.select_next_item()";
          "<C-k>" = "cmp.mapping.select_prev_item()";
          "<C-e>" = "cmp.mapping.abort()";
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<S-CR>" =
            "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
        };
      };
    };

    cmp-nvim-lsp.enable = true;
    cmp-buffer.enable = true;
    cmp_luasnip.enable = true;
    cmp-cmdline.enable = true;
    #autoclose.enable = true;
    indent-blankline = { enable = true; };

    lz-n = {
      enable = true;
      plugins = [{
        __unkeyed-1 = "telescope.nvim";
        cmd = [ "Telescope" ];
        keys = [
          {
            __unkeyed-1 = "<leader>fa";
            __unkeyed-2 = "<CMD>Telescope autocommands<CR>";
            desc = "Telescope autocommands";
          }
          {
            __unkeyed-1 = "<leader>fb";
            __unkeyed-2 = "<CMD>Telescope buffers<CR>";
            desc = "Telescope buffers";
          }
        ];
      }];
    };
  };
}
