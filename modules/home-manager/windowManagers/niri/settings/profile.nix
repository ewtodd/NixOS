{ config, lib, osConfig, pkgs, ... }:

with lib;
let
  primaryMonitor = if osConfig.DeviceType == "desktop" then "DP-3" else "eDP-1";
  secondaryMonitor = if osConfig.DeviceType == "desktop" then
    "HDMI-A-1"
  else
    (if osConfig.DeviceType == "laptop" then "HDMI-A-2" else "DP-3");
in {
  config = mkMerge [
    (mkIf (config.Profile == "work") {
      wayland.windowManager.niri.settings = {
        workspaces."bchat" = {
          name = "bchat";
          open-on-output = primaryMonitor;
        };
        workspaces."ccalendar" = {
          name = "ccalendar";
          open-on-output = secondaryMonitor;
        };

        window-rules = [
          {
            matches = [{ app-id = "Slack"; }];
            open-on-workspace = "bchat";
          }
          {
            matches = [{ app-id = "thunderbird"; }];
            open-on-workspace = "bchat";
          }
          {
            matches = [{ app-id = "Todoist"; }];
            open-on-workspace = "ccalendar";
            default-column-width.proportion = 1.0;
          }

        ] ++ lib.optionals (osConfig.DeviceType == "laptop") [{
          matches = [{ app-id = "firefox"; }];
          default-column-width.proportion = 0.75;
        }];
        spawn-at-startup = [
          {
            command =
              [ "sh" "-c" "thunderbird  && niri msg action move-column-left" ];
          }
          {
            command = [
              "sh"
              "-c"
              "sleep 2 && ${pkgs.slack}/bin/slack && niri msg action move-column-right"
            ];
          }
          {
            command = [
              "sh"
              "-c"
              "sleep 2 && ${pkgs.todoist-electron}/bin/todoist-electron"
            ];
          }
        ];
      };
    })

    (mkIf (config.Profile == "play") {
      wayland.windowManager.niri.settings = {

        workspaces."bmedia" = {
          name = "bmedia";
          open-on-output = primaryMonitor;
        };
        workspaces."cchat" = {
          name = "cchat";
          open-on-output = secondaryMonitor;
        };

        binds = {
          "Mod+Shift+t".action.spawn =
            [ "firefox" "--new-window" "https://monkeytype.com" ];
        };
        window-rules = [
          {
            matches = [{ app-id = "steam"; }];
            open-on-workspace = "bmedia";
            default-column-width.proportion = 0.5;
          }
          {
            matches = [{ app-id = "spotify"; }];
            open-on-workspace = "bmedia";
            default-column-width.proportion = 0.5;
          }
          {
            matches = [{ app-id = "signal"; }];
            open-on-workspace = "cchat";
            default-column-width.proportion = 1.0;
          }
        ] ++ lib.optionals (osConfig.DeviceType == "laptop") [{
          matches = [{ app-id = "firefox"; }];
          default-column-width.proportion = 0.75;
        }];
        spawn-at-startup = [
          {
            command = [
              "sh"
              "-c"
              "sleep 2 && steam && niri msg action move-column-left"
            ];
          }
          { command = [ "sh" "-c" "sleep 2 && spotify" ]; }
          {
            command =
              [ "${pkgs.signal-desktop}/bin/signal-desktop" "--use-tray-icon" ];
          }
        ];
      };
    })
  ];
}
