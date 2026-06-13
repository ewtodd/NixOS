{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:

let
  colors = config.scheme;
  sysOpts = if osConfig != null then osConfig.systemOptions else null;
  # A host gets FIM completion when its own llama-swap serves a model named
  # `qwen-fim` (nvim then talks to it on localhost). e-owner hosts boot
  # FIM-first; everyone else boots cmp-first — both have the <leader>f toggle.
  # This block must stay here, NOT in plugins.nix: that file is shared with
  # the standalone `nix run .#neovim` package (mkNeovim in flake.nix), which
  # evaluates without osConfig.
  hasFim =
    sysOpts != null
    && sysOpts.services.llamaSwap.enable
    && sysOpts.services.llamaSwap.models ? "qwen-fim";
  fimDefault = sysOpts != null && sysOpts.owner.e.enable;
in
{
  programs.nixvim = {
    imports = [
      ./opts.nix
      ./keymaps.nix
      ./plugins.nix
      ./performance.nix
      ./split.nix
    ];
    enable = true;

    # FIM ghost-text completion off the host's local llama-swap, with its
    # default keybinds: <Tab> accept suggestion, <S-Tab> accept first line.
    # Completion is modal — one engine at a time, <leader>f toggles between
    # FIM and cmp — so Tab is never ambiguous. /upstream/<id>/ proxies
    # straight to that model's llama-server and auto-loads it on first
    # request, so the infill endpoint works through llama-swap.
    extraPlugins = lib.mkIf hasFim [ pkgs.vimPlugins.llama-vim ];
    extraConfigLua = lib.mkIf hasFim ''
      vim.g.llama_config = {
        endpoint_fim = "http://127.0.0.1:8080/upstream/qwen-fim/infill",
        -- 1 = stats in the statusline instead of inline next to the ghost text
        show_info = 1,
        -- Instruction mode is unused (opencode + son-of-anton cover that on
        -- e-devices; the v-fleet uses Claude). Park its keymaps on dead <Plug>
        -- names so it stops hijacking normal-mode <Tab>/<Esc>, and leave
        -- endpoint_inst unset.
        keymap_inst_trigger  = "<Plug>(llama-inst-disabled-trigger)",
        keymap_inst_rerun    = "<Plug>(llama-inst-disabled-rerun)",
        keymap_inst_continue = "<Plug>(llama-inst-disabled-continue)",
        keymap_inst_accept   = "<Plug>(llama-inst-disabled-accept)",
        keymap_inst_cancel   = "<Plug>(llama-inst-disabled-cancel)",
      }

      -- Modal completion: FIM-only (llama.vim) or cmp-only, never both. cmp's
      -- `enabled` function reads this flag. e-devices start in FIM mode;
      -- others start in cmp mode (so disable llama.vim at startup there).
      vim.g.fim_only = ${if fimDefault then "true" else "false"}
      if not vim.g.fim_only then
        vim.cmd("LlamaDisable")
      end
      vim.keymap.set("n", "<leader>f", function()
        vim.g.fim_only = not vim.g.fim_only
        vim.cmd(vim.g.fim_only and "LlamaEnable" or "LlamaDisable")
        vim.notify("completion: " .. (vim.g.fim_only and "FIM (llama.vim)" or "cmp"))
      end, { desc = "Toggle FIM / cmp completion" })
    '';

    # Completion is modal on FIM hosts: FIM-only or cmp-only, toggled with
    # <leader>f (see extraConfigLua above). cmp consults `enabled` on every
    # completion attempt, so flipping the flag kills/revives it instantly —
    # no Tab ambiguity, no popup fighting the ghost text.
    plugins.cmp.settings.enabled = lib.mkIf hasFim {
      __raw = "function() return not vim.g.fim_only end";
    };

    colorschemes = {
      base16 = {
        enable = true;
        colorscheme = lib.mapAttrs' (name: value: lib.nameValuePair name "#${value}") (
          lib.filterAttrs (name: _: builtins.match "base0[0-9A-F]" name != null) colors
        );
        settings = {
          telescope_borders = true;
        };
      };
    };
  };

  xdg.desktopEntries = lib.mkIf (!pkgs.stdenv.isDarwin) {
    nvim = {
      name = "Neovim";
      genericName = "Text Editor";
      comment = "Edit text files";
      exec = "kitty nvim %F";
      icon = "nvim";
      type = "Application";
      terminal = false;
      categories = [
        "Utility"
        "TextEditor"
        "Development"
      ];
    };
  };
}
