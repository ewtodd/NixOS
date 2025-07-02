{ config, lib, ... }:

with lib;

{
  config = mkMerge [
    (mkIf (config.Profile == "work") {
      wayland.windowManager.sway = {
        config = {

          # Work-specific keybindings
          keybindings = {
            "Mod4+g" =
              "exec firefox --new-window -url https://umgpt.umich.edu/ -new-tab -url https://www.perplexity.ai/";
          };

          startup = [
            {
              command =
                "exec firefox --new-instance --new-window -url https://github.com/ewtodd/ANSG-AnalysisFramework -new-tab -url https://github.com/ewtodd/ANSG-Analysis -new-tab -url perplexity.ai";
            }
            { command = "exec thunderbird"; }
            { command = "exec slack"; }
            { command = "sh -c 'sleep 10 && birdtray'"; }
          ];
        };

        extraConfig = ''
          exec swaybg -i /etc/nixos/modules/home-manager/windowManagers/sway/wallpapers/kanagawa.png 
        '';
      };
    })

    (mkIf (config.Profile == "play") {
      wayland.windowManager.sway = {
        config = {

          # Play-specific keybindings
          keybindings = {
            "Mod4+Shift+t" = "exec firefox --new-window https://monkeytype.com";
          };

          # Play-specific startup applications
          startup = [
            { command = "steam"; }
            { command = "spotify"; }
            { command = "sh -c 'sleep 2 && signal-desktop --use-tray-icon'"; }
            { command = "thunderbird"; }
            { command = "sh -c 'sleep 10 && birdtray'"; }
          ];
        };

        extraConfig = ''
          exec swaybg -i /etc/nixos/modules/home-manager/windowManagers/sway/wallpapers/tokyonight.png
        '';
      };
    })
  ];
}
