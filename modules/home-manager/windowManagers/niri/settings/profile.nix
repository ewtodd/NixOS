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
      programs.niri.settings = {
        workspaces."afirefox" = {
          name = "afirefox";
          open-on-output = primaryMonitor;
        };
        workspaces."bchat" = {
          name = "bchat";
          open-on-output = primaryMonitor;
        };
        workspaces."ccalendar" = {
          name = "ccalendar";
          open-on-output = secondaryMonitor;
        };

        binds = with config.lib.niri.actions; {
          "Mod+g".action.spawn =
            [ "firefox" "--new-window" "-url" "https://umgpt.umich.edu/" ];
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
        ];
        # Work-specific startup applications
        spawn-at-startup = [
          {
            command = [
              "sh"
              "-c"
              "firefox && niri msg action move-window-to-workspace afirefox"
            ];
          }
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
          {
            command = [ "sh" "-c" "niri msg action focus-workspace afirefox" ];
          }
        ];
      };
    })

    (mkIf (config.Profile == "play") {
      programs.niri.settings = {

        workspaces."afirefox" = {
          name = "afirefox";
          open-on-output = primaryMonitor;
        };

        workspaces."bmedia" = {
          name = "bmedia";
          open-on-output = primaryMonitor;
        };
        workspaces."cchat" = {
          name = "cchat";
          open-on-output = secondaryMonitor;
        };

        # Play-specific keybindings
        binds = with config.lib.niri.actions; {
          "Mod+Shift+t".action =
            spawn "firefox" "--new-window" "https://monkeytype.com";
        };
        window-rules = [
          {
            matches = [{ app-id = "steam"; }];
            open-on-workspace = "bmedia";
          }
          {
            matches = [{ app-id = "spotify"; }];
            open-on-workspace = "bmedia";
          }

          {
            matches = [{ app-id = "signal"; }];
            open-on-workspace = "cchat";
            default-column-width.proportion = 1.0;
          }
        ];
        # Play-specific startup applications
        spawn-at-startup = [
          {
            command = [
              "sh"
              "-c"
              "firefox && niri msg action move-window-to-workspace afirefox"
            ];
          }

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
          {
            command = [ "sh" "-c" "niri msg action focus-workspace afirefox" ];
          }
        ];
      };
    })
  ];
}
