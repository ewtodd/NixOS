inputs:
{ pkgs, ... }:
{
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      pname = "split.nvim";
      version = "0-unstable-${
        builtins.substring 0 8 (inputs.split-nvim-src.lastModifiedDate or "00000000")
      }";
      src = inputs.split-nvim-src;
    })
  ];
  extraConfigLua = ''
                
    -- split.nvim takes only Lua patterns, which cannot exclude a "." after an
    -- abbreviation. Wrap its match finder (algorithm.lua calls it through the
    -- module table) to drop matches whose "." ends a listed word. Case-sensitive,
    -- so "No." and "etc." stay out: both often end a sentence.
    local split_utils = require('split.utils')
    local gfind = split_utils.gfind
    local abbreviations = {}
    for _, a in ipairs({
      "Dr", "Prof", "Mr", "Mrs", "Ms", "St", "Jr", "Sr",
      "e.g", "i.e", "cf", "vs", "al", "approx", "U.S",
      "Fig", "Figs", "Eq", "Eqs", "Sec", "Secs", "Ref", "Refs",
      "Tab", "Ch", "Vol", "pp",
    }) do abbreviations[a] = true end
    split_utils.gfind = function(x, pattern, plain)
      return vim.tbl_filter(function(pos)
        return x:sub(pos[1], pos[1]) ~= "."
          or not abbreviations[x:sub(1, pos[1] - 1):match("[%a%.]+$")]
      end, gfind(x, pattern, plain))
    end

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
}
