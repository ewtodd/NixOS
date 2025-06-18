{ config, lib, pkgs, ... }: {
  programs.nixvim.keymaps = [
    {
      action = "<cmd>IronHide<CR>";
      key = "<S-esc>";
      mode = [ "n" "i" "v" ];
      options = { nowait = true; };
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
      key = "<S-CR>";
      action = ":MoltenEvaluateOperator<CR>ip";
      mode = "n";
      options.desc = "Evaluate current cell";
    }

    # Initialize molten
    {
      key = "<localleader>mi";
      action = ":MoltenInit<CR>";
      mode = "n";
      options.desc = "Initialize Molten";
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

    # Show/hide output
    {
      key = "<localleader>os";
      action = ":noautocmd MoltenEnterOutput<CR>";
      mode = "n";
      options.desc = "Show output";
    }

    {
      key = "<localleader>oh";
      action = ":MoltenHideOutput<CR>";
      mode = "n";
      options.desc = "Hide output";
    }

    # Delete cell
    {
      key = "<localleader>md";
      action = ":MoltenDelete<CR>";
      mode = "n";
      options.desc = "Delete cell";
    }
  ];
}
