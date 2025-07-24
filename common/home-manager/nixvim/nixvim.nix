{ config, lib, pkgs, ... }:

{
  imports =
    [ ./opts.nix ./keymaps.nix ./plugins.nix ./performance.nix ./split.nix ];

  config = let profile = config.Profile;
  in {
    programs.nixvim = {
      colorschemes = if (profile == "work") then {
        base16 = {
          enable = true;
          colorscheme = "eris";
        };
      } else {
        rose-pine = { enable = true; };
      };
    };
  };
}
