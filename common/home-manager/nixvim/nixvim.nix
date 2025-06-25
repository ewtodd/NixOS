{ config, lib, pkgs, ... }:

with lib; {
  imports = [ ./opts.nix ./keymaps.nix ./plugins.nix ./performance.nix ];

  options.nixvimProfile = mkOption {
    type = types.enum [ "work" "play" ];
    default = "play";
    description = "Profile for nixvim (work/play)";
  };

  config = let profile = config.nixvimProfile;
  in {
    programs.nixvim = {
      colorschemes = if (profile == "work") then {
        dracula = {
          enable = true;
          settings.colorterm = false;
        };
      } else {
        tokyonight = {
          enable = true;
          settings.style = "night";
        };
      };
    };
  };
}
