{ config, lib, osConfig, ... }:

with lib;
let
  primaryMonitor =
    if osConfig.DeviceType == "desktop" then "HDMI-A-3" else "eDP-1";
  secondaryMonitor = "HDMI-A-2";
in {
  config = mkMerge [
    (mkIf (config.Profile == "work") {
      programs.niri.settings = {
        workspaces."slack" = {
          name = "slack";
          open-on-output = secondaryMonitor;
        };
        workspaces."thunderbird" = {
          name = "thunderbird";
          open-on-output = secondaryMonitor;
        };
        binds = with config.lib.niri.actions; {
          "Mod+g".action =
            spawn "firefox" "--new-window" "-url" "https://umgpt.umich.edu/"
            "-new-tab" "-url" "https://www.perplexity.ai/";
          "Mod+5".action.focus-workspace = "slack";
          "Mod+6".action.focus-workspace = "thunderbird";
        };

        window-rules = [
          {
            matches = [{ app-id = "Slack"; }];
            open-on-workspace = "slack";
          }
          {
            matches = [{ app-id = "thunderbird"; }];
            open-on-workspace = "thunderbird";
          }
        ];
        # Work-specific startup applications
        spawn-at-startup = [
          {
            command = [
              "sh"
              "-c"
              "firefox --new-instance --new-window -url https://github.com/ewtodd/ANSG-AnalysisFramework -new-tab -url https://github.com/ewtodd/ANSG-Analysis -new-tab -url perplexity.ai"
            ];
          }
          { command = [ "thunderbird" ]; }
          { command = [ "slack" ]; }
          { command = [ "sh" "-c" "sleep 10 && birdtray" ]; }
          {
            command = [
              "swaybg"
              "-i"
              "/etc/nixos/modules/home-manager/windowManagers/niri/wallpapers/kanagawa.png"
            ];
          }
        ];
      };
    })

    (mkIf (config.Profile == "play") {
      programs.niri.settings = {

        workspaces."steam" = {
          name = "steam";
          open-on-output = primaryMonitor;
        };
        workspaces."thunderbird" = {
          name = "thunderbird";
          open-on-output = secondaryMonitor;
        };
        workspaces."signal" = {
          name = "signal";
          open-on-output = secondaryMonitor;
        };
        workspaces."spotify" = {
          name = "spotiy";
          open-on-output = primaryMonitor;
        };

        # Play-specific keybindings
        binds = with config.lib.niri.actions; {
          "Mod+Shift+t".action =
            spawn "firefox" "--new-window" "https://monkeytype.com";
          "Mod+5".action.focus-workspace = "signal";
          "Mod+6".action.focus-workspace = "thunderbird";
          "Mod+7".action.focus-workspace = "steam";
          "Mod+8".action.focus-workspace = "spotify";
        };
        window-rules = [
          {
            matches = [{ app-id = "thunderbird"; }];
            open-on-workspace = "thunderbird";
          }
          {
            matches = [{ app-id = "steam"; }];
            open-on-workspace = "steam";
          }
          {
            matches = [{ app-id = "spotify"; }];
            open-on-workspace = "spotify";
          }
          {
            matches = [{ app-id = "signal"; }];
            open-on-workspace = "signal";
          }
        ];
        # Play-specific startup applications
        spawn-at-startup = [
          { command = [ "steam" ]; }
          { command = [ "spotify" ]; }
          {
            command = [ "sh" "-c" "sleep 2 && signal-desktop --use-tray-icon" ];
          }
          { command = [ "thunderbird" ]; }
          { command = [ "sh" "-c" "sleep 10 && birdtray" ]; }
          {
            command = [
              "swaybg"
              "-i"
              "/etc/nixos/modules/home-manager/windowManagers/niri/wallpapers/tokyonight.png"
            ];
          }
        ];
      };
    })
  ];
}
