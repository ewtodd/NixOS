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
                  
      require('split').setup({
        keymaps = {
          ["gs"] = {
            pattern = ",",
            operator_pending = true,
            interactive = false,
          },
          ["g."] = {
            pattern = "[%.?!]%s+",
            operator_pending = true,
            interactive = false,  
          },
        },
      })

      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = {"*.tex", "*.md", "*.markdown"},
        callback = function()
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_feedkeys("ggVGg.", "x", false)
        vim.defer_fn(function()
            vim.api.nvim_win_set_cursor(0, cursor_pos)
          end, 10)
        end,
      })
    '';
  };
}
