{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "split.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "wurli";
          repo = "split.nvim";
          rev = "main";
          sha256 = "sha256-nN2hV95KCiauvDgnWtHVbvpHz2oVyCRvwWt+e02EhUA=";
        };
      })
    ];
    extraConfigLua = ''
                  
      -- In your split.nvim setup
      require('split').setup({
        keymaps = {
          ["gs"] = {
            pattern = ",",
            operator_pending = true,
            interactive = false,
          },
          -- Add a dedicated sentence splitting keymap
          ["g."] = {
            pattern = "[%.?!]%s+",
            operator_pending = true,
            interactive = false,  -- This is key!
          },
        },
      })

      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = {"*.tex", "*.md", "*.markdown"},
        callback = function()
        vim.api.nvim_feedkeys("ggVGg.", "x", false)
        end,
      })
    '';
  };
}
