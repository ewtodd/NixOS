{ config, lib, osConfig, ... }:

with lib;
let
  primaryMonitor = if osConfig.DeviceType == "desktop" then "DP-3" else "eDP-1";
  secondaryMonitor =
    if osConfig.DeviceType == "desktop" then "HDMI-A-1" else "DP-3";
in {
  config = mkMerge [
    (mkIf (config.Profile == "work") {
      wayland.windowManager.sway = {
        config = {
          assigns = {
            "3" = [ ] ++ optionals (osConfig.DeviceType != "desktop") [{
              app_id = "Slack";
            }];
            "4" = [ ] ++ optionals (osConfig.DeviceType != "desktop") [{
              app_id = "Todoist";
            }];
            "5" = [ ] ++ optionals (osConfig.DeviceType == "desktop") [{
              app_id = "Todoist";
            }];

            "2" = [{ app_id = "thunderbird"; }]
              ++ optionals (osConfig.DeviceType == "desktop") [{
                app_id = "Slack";
              }];
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
            { command = "thunderbird"; }
            {
              command =
                "slack --enable-features=UseOzonePlatform --ozone-platform=wayland";
            }
            {
              command =
                "todoist-electron --enable-features=UseOzonePlatform --ozone-platform=wayland";
            }
            { command = "swaymsg 'workspace 1'"; }
          ];
        };
      };
    })

    (mkIf (config.Profile == "play") {
      wayland.windowManager.sway = {
        config = {
          assigns = {
            "2" = [{ class = "steam"; }]
              ++ optionals (osConfig.DeviceType == "desktop") [{
                app_id = "spotify";
              }];
            "3" = [ ] ++ optionals (osConfig.DeviceType != "desktop") [{
              app_id = "spotify";
            }];
            "5" = [{ app_id = "signal"; }];
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
          ];
        };
      };
    })
  ];
}
