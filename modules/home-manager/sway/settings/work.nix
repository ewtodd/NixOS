{ config, pkgs, ... }: {

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
      exec swaybg -i /etc/nixos/modules/home-manager/sway/wallpapers/work_dracula.png 
    '';
  };
}
