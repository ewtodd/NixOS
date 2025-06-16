{ config, pkgs, ... }: {

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
        "Mod4+p" =
          "exec firefox --new-window -url https://search.nixos.org/packages -new-tab -url https://search.nixos.org/options?";
      };

      # Play-specific startup applications
      startup = [
        { command = "steam"; }
        { command = "spotify"; }
        { command = "sh -c 'sleep 2 && signal-desktop --use-tray-icon'"; }
        { command = "thunderbird"; }
        {
          command = "sh -c 'sleep 10 && birdtray'";
        }
        # { command = "./scripts/startup-terminals.sh"; }
      ];
    };

    extraConfig = ''
      exec swaybg -i /etc/nixos/modules/home-manager/sway/wallpapers/play.jpg
    '';
  };
}
