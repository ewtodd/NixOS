{ config, lib, pkgs, ... }: {

  programs.nixvim.keymaps = [
    {
      action = "<cmd>WhichKey<CR>";
      key = "<A-w>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>lua vim.lsp.buf.definition()<CR>";
      key = "<A-f>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      mode = "n";
      key = "zl";
      action = "<cmd>ZkLinks<CR>";
      options.silent = true;
    }
    {
      mode = "n";
      key = "zb";
      action = "<cmd>ZkBacklinks<CR>";
      options.silent = true;
    }
    {
      mode = "n";
      key = "zn";
      action = "<cmd>ZkNotes<CR>";
      options.silent = true;
    }
    {
      action = "<cmd>Telescope file_browser<CR>";
      key = "<C-f>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferClose<CR>";
      key = "<C-w>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferGoto 1<CR>";
      key = "<A-1>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferGoto 2<CR>";
      key = "<A-2>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferGoto 3<CR>";
      key = "<A-3>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferGoto 4<CR>";
      key = "<A-4>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferGoto 5<CR>";
      key = "<A-5>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferGoto 6<CR>";
      key = "<A-6>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferGoto 7<CR>";
      key = "<A-7>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferGoto 8<CR>";
      key = "<A-8>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferGoto 9<CR>";
      key = "<A-9>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferLast<CR>";
      key = "<A-0>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferMovePrevious<CR>";
      key = "<A-,>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      action = "<cmd>BufferMoveNext<CR>";
      key = "<A-.>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
    }
    {
      key = "<C-e>";
      action = ":MoltenEvaluateOperator<CR>";
      mode = [ "n" "i" "v" ];
      options.nowait = true;
      options.desc = "Evaluate current cell";
    }

    # Initialize molten
    {
      key = "<C-p>";
      action = "<cmd>MoltenInit nix-python<CR>";
      mode = [ "n" "i" "v" ];
      options.nowait = true;
      options.desc = "Initialize Molten for Python";
    }

    # Evaluate line
    {
      key = "<localleader>rl";
      action = ":MoltenEvaluateLine<CR>";
      mode = "n";
      options.desc = "Evaluate line";
    }

    # Re-evaluate cell
    {
      key = "<localleader>rr";
      action = ":MoltenReevaluateCell<CR>";
      mode = "n";
      options.desc = "Re-evaluate cell";
    }

    # Evaluate visual selection
    {
      key = "<localleader>r";
      action = ":<C-u>MoltenEvaluateVisual<CR>gv";
      mode = "v";
      options.desc = "Evaluate visual selection";
    }

    {
      key = "<localleader>md";
      action = ":MoltenDelete<CR>";
      mode = "n";
      options.desc = "Delete cell";
    }
  ];
}
