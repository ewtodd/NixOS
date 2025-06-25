{ config, lib, pkgs, ... }:

with lib;

let
  # Receive profile as separate argument
  profile = config.programs.nixvimProfile;
in {
  options.programs.nixvimProfile = mkOption {
    type = types.enum [ "work" "play" ];
    default = "play";
    description = "Which profile to use (work or play)";
  };

  config = mkIf config.programs.nixvim.enable {

    programs.nixvim = {
      colorschemes = if (profile == "work") then {
        dracula = {
          enable = true;
          settings.colorterm = false;
        };
      } else {
        tokyonight = {
          enable = true;
          style = "night";
        };
      };
    };
  };
}
