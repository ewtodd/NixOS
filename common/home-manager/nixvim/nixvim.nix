{ config, lib, pkgs, ... }:

{
  imports =
    [ ./opts.nix ./keymaps.nix ./plugins.nix ./performance.nix ./split.nix ];

  config = let profile = config.Profile;
  in {
    programs.nixvim = {
      colorschemes = if (profile == "play") then {
        rose-pine = { enable = true; };
      } else {
        gruvbox = {
          enable = true;
          settings.terminal_colors = true;
          settings.transparent_mode = true;
        };
      };
    };
  };
}
