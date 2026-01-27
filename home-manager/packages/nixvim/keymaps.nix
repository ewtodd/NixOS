{ ... }:
{

  programs.nixvim.keymaps = [
    {
      action = "<cmd>WhichKey<CR>";
      key = "<A-w>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>lua vim.lsp.buf.definition()<CR>";
      key = "<A-f>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>Telescope file_browser<CR>";
      key = "<C-f>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferClose<CR>";
      key = "<C-w>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferGoto 1<CR>";
      key = "<A-1>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferGoto 2<CR>";
      key = "<A-2>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferGoto 3<CR>";
      key = "<A-3>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferGoto 4<CR>";
      key = "<A-4>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferGoto 5<CR>";
      key = "<A-5>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferGoto 6<CR>";
      key = "<A-6>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferGoto 7<CR>";
      key = "<A-7>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferGoto 8<CR>";
      key = "<A-8>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferGoto 9<CR>";
      key = "<A-9>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferLast<CR>";
      key = "<A-0>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferMovePrevious<CR>";
      key = "<A-,>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>BufferMoveNext<CR>";
      key = "<A-.>";
      mode = [
        "n"
        "i"
        "v"
      ];
      options = {
        nowait = true;
      };
    }
    {
      action = "<cmd>lua Snacks.terminal.toggle()<CR>";
      key = "<leader>tt";
      mode = [ "n" ];
      options = {
        desc = "Toggle terminal";
        nowait = true;
      };
    }
    {
      action = "<cmd>wincmd h<CR>";
      key = "<C-h>";
      mode = [
        "n"
        "t"
      ];
      options = {
        desc = "Go to left window";
        nowait = true;
      };
    }
    {
      action = "<cmd>wincmd l<CR>";
      key = "<C-l>";
      mode = [
        "n"
        "t"
      ];
      options = {
        desc = "Go to right window";
        nowait = true;
      };
    }
    {
      action = "<cmd>wincmd j<CR>";
      key = "<C-j>";
      mode = [
        "n"
        "t"
      ];
      options = {
        desc = "Go to below window";
        nowait = true;
      };
    }
    {
      action = "<cmd>wincmd k<CR>";
      key = "<C-k>";
      mode = [
        "n"
        "t"
      ];
      options = {
        desc = "Go to above window";
        nowait = true;
      };
    }
    {
      action = "<cmd>vertical resize -5<CR>";
      key = "<C-Right>";
      mode = [
        "n"
        "t"
      ];
      options = {
        desc = "Decrease window width";
        nowait = true;
      };
    }
    {
      action = "<cmd>vertical resize +5<CR>";
      key = "<C-Left>";
      mode = [
        "n"
        "t"
      ];
      options = {
        desc = "Increase window width";
        nowait = true;
      };
    }
    {
      action = "<cmd>resize -5<CR>";
      key = "<C-Up>";
      mode = [
        "n"
        "t"
      ];
      options = {
        desc = "Decrease window height";
        nowait = true;
      };
    }
    {
      action = "<cmd>resize +5<CR>";
      key = "<C-Down>";
      mode = [
        "n"
        "t"
      ];
      options = {
        desc = "Increase window height";
        nowait = true;
      };
    }
    {
      action = "<cmd>VimtexCompile<CR>";
      key = "<leader>vc";
      mode = [
        "n"
        "t"
      ];
      options = {
        desc = "VimtexCompile";
        nowait = true;
      };
    }
  ];
}
