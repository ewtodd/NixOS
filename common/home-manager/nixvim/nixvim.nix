{ config, lib, pkgs, ... }:

{
  imports = [ ./opts.nix ./keymaps.nix ./plugins.nix ./performance.nix ];

  config = let profile = config.Profile;
  in {
    programs.nixvim = {
      colorschemes = if (profile == "play") then {
        dracula = {
          enable = true;
          settings.colorterm = false;
        };
      } else {
        catppuccin = {
          enable = true;
          settings.flavour = "latte";
        };
      };
    };
  };
}
