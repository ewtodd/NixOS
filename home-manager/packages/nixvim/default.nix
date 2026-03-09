{
  config,
  lib,
  pkgs,
  ...
}:

let
  colors = config.scheme;
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
        colorscheme = lib.mapAttrs' (name: value: lib.nameValuePair name "#${value}")
          (lib.filterAttrs (name: _: builtins.match "base0[0-9A-F]" name != null) colors);
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
