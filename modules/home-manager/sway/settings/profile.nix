{ config, lib, ... }:

with lib;

{
  config = mkMerge [
    (mkIf (config.Profile == "work") {
      wayland.windowManager.sway = {
        config = {
          assigns = {
            "2" = [{ app_id = "thunderbird"; }];
            "3" = [{ app_id = "Slack"; }];
          };

          # Work-specific keybindings
          keybindings = {
            "Mod4+g" =
              "exec firefox --new-window -url https://umgpt.umich.edu/ -new-tab -url https://www.perplexity.ai/";
            # Brightness controls for laptop
            "XF86MonBrightnessUp" =
              "exec brightnessctl --device='acpi_video0' set +5%";
            "XF86MonBrightnessDown" =
              "exec brightnessctl --device='acpi_video0' set 5%-";
          };

          # Work-specific startup applications
          startup = [
            {
              command =
                "swaymsg 'workspace 1; exec firefox --new-instance --new-window -url https://github.com/ewtodd/ANSG-AnalysisFramework -new-tab -url https://github.com/ewtodd/ANSG-Analysis -new-tab -url perplexity.ai'";
            }
            { command = "swaymsg 'workspace 2; exec thunderbird'"; }
            { command = "swaymsg 'workspace 3; exec slack'"; }
            { command = "swaymsg 'workspace 1'"; }
            { command = "sh -c 'sleep 10 && birdtray'"; }
          ];
        };

        extraConfig = ''
          exec swaybg -i /etc/nixos/modules/home-manager/sway/wallpapers/kanagawa.png
        '';
      };
    })

    (mkIf (config.Profile == "play") {
      wayland.windowManager.sway = {
        config = {
          assigns = {
            "2" = [{ class = "steam"; }];
            "3" = [{ app_id = "spotify"; }];
            "4" = [{ app_id = "thunderbird"; }];
            "5" = [{ app_id = "signal"; }];
          };

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
          exec swaybg -i /etc/nixos/modules/home-manager/sway/wallpapers/tokyonight.png
        '';
      };
    })
  ];
}
