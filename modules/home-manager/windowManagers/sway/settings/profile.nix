{ config, lib, osConfig, ... }:

with lib;
let
  primaryMonitor =
    if osConfig.DeviceType == "desktop" then "HDMI-A-1" else "eDP-1";
  secondaryMonitor =
    if osConfig.DeviceType == "desktop" then "DP-3" else "HDMI-A-2";
in {
  config = mkMerge [
    (mkIf (config.Profile == "work") {
      wayland.windowManager.sway = {
        config = {
          assigns = {
            "3" = [{ app_id = "Slack"; }];
            "2" = [{ app_id = "thunderbird"; }];
          };
          workspaceOutputAssign = [
            {
              workspace = "1";
              output = "${primaryMonitor}";
            }
            {
              workspace = "2";
              output = "${primaryMonitor}";
            }
            {
              workspace = "3";
              output = "${primaryMonitor}";
            }
            {
              workspace = "4";
              output = "${primaryMonitor}";
            }
            {
              workspace = "5";
              output = "${secondaryMonitor}";
            }
            {
              workspace = "6";
              output = "${secondaryMonitor}";
            }

          ];

          # Work-specific keybindings
          keybindings = {
            "Mod4+g" =
              "exec firefox --new-window -url https://umgpt.umich.edu/";
          };

          startup = [
            {
              command =
                "swaymsg 'workspace 5; exec firefox --new-instance --new-window -url https://github.com/ewtodd -new-tab -url llm.ethanwtodd.com'";
            }
            { command = "swaymsg 'workspace 2; exec thunderbird'"; }
            { command = "swaymsg 'workspace 3; exec slack'"; }
            { command = "swaymsg 'workspace 1'"; }
            { command = "sh -c 'sleep 10 && birdtray'"; }
          ];
        };
        extraConfig = ''
          layer_effects "waybar" blur enable; shadows enable
        '';
      };
    })

    (mkIf (config.Profile == "play") {
      wayland.windowManager.sway = {
        config = {
          assigns = {
            "2" = [{ class = "steam"; }];
            "3" = [{ app_id = "spotify"; }];
            "5" = [{ app_id = "signal"; }];
            "4" = [{ app_id = "thunderbird"; }];
          };
          workspaceOutputAssign = [
            {
              workspace = "1";
              output = "${primaryMonitor}";
            }
            {
              workspace = "2";
              output = "${primaryMonitor}";
            }
            {
              workspace = "3";
              output = "${primaryMonitor}";
            }
            {
              workspace = "4";
              output = "${primaryMonitor}";
            }
            {
              workspace = "5";
              output = "${secondaryMonitor}";
            }
            {
              workspace = "6";
              output = "${secondaryMonitor}";
            }

          ];

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
          layer_effects "waybar" blur enable; shadows enable
        '';
      };
    })
  ];
}
