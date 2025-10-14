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

        binds = with config.lib.niri.actions; {
          "Mod+g".action.spawn =
            [ "firefox" "--new-window" "-url" "https://umgpt.umich.edu/" ];
          "Mod+1".action.focus-workspace = "afirefox";
          "Mod+Shift+1".action.move-window-to-workspace = "afirefox";
          "Mod+2".action.focus-workspace = "bchat";
          "Mod+Shift+2".action.move-window-to-workspace = "bchat";
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
            open-on-workspace = "bchat";
          }
          {
            matches = [{ app-id = "firefox"; }];
            open-on-workspace = "afirefox";
          }
        ];
        # Work-specific startup applications
        spawn-at-startup = [
          { command = [ "firefox" ]; }
          { command = [ "thunderbird" ]; }
          {
            command = [
              "${pkgs.slack}/bin/slack"
              "--enable-features=UseOzonePlatform"
              "--ozone-platform=wayland"
            ];
          }
          {
            command = [
              "sh"
              "-c"
              "${pkgs.todoist-electron}/bin/todoist-electron"
              "--enable-features=UseOzonePlatform"
              "--ozone-platform=wayland"
            ];
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

        workspaces."bsteam" = {
          name = "bsteam";
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
          "Mod+1".action.focus-workspace = "afirefox";
          "Mod+Shift+1".action.move-window-to-workspace = "afirefox";
          "Mod+2".action.focus-workspace = "bsteam";
          "Mod+Shift+2".action.move-window-to-workspace = "bsteam";
          "Mod+3".action.focus-workspace = "cchat";
          "Mod+Shift+3".action.move-window-to-workspace = "cchat";
        };
        window-rules = [
          {
            matches = [{ app-id = "steam"; }];
            open-on-workspace = "bsteam";
          }

          {
            matches = [{ app-id = "signal"; }];
            open-on-workspace = "cchat";
          }
          {
            matches = [{ app-id = "firefox"; }];
            open-on-workspace = "afirefox";
          }

        ];
        # Play-specific startup applications
        spawn-at-startup = [
          { command = [ "firefox" ]; }
          { command = [ "sh" "-c" "${pkgs.steam}/bin/steam" ]; }
          {
            command =
              [ "${pkgs.signal-desktop}/bin/signal-desktop" "--use-tray-icon" ];
          }

        ];
      };
    })
  ];
}
