{
  config,
  lib,
  pkgs,
  ...
}:

let
  colors = config.colorScheme.palette;
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
    colorschemes = {
      base16 = {
        enable = true;
        colorscheme = builtins.mapAttrs (name: value: "#${value}") colors;
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
