{ config, lib, ... }:

with lib;

{
  config = mkMerge [
    (mkIf (config.Profile == "work") {
      programs.niri.settings = {

        binds = with config.lib.niri.actions; {
          "Mod+g".action =
            spawn "firefox" "--new-window" "-url" "https://umgpt.umich.edu/"
            "-new-tab" "-url" "https://www.perplexity.ai/";
        };

        # Work-specific startup applications
        spawn-at-startup = [
          {
            command = [
              "sh"
              "-c"
              "niri msg action focus-workspace --reference-workspace 1 && firefox --new-instance --new-window -url https://github.com/ewtodd/ANSG-AnalysisFramework -new-tab -url https://github.com/ewtodd/ANSG-Analysis -new-tab -url perplexity.ai"
            ];
          }
          {
            command = [
              "sh"
              "-c"
              "niri msg action focus-workspace --reference-workspace 2 && thunderbird"
            ];
          }
          {
            command = [
              "sh"
              "-c"
              "niri msg action focus-workspace --reference-workspace 3 && slack"
            ];
          }
          {
            command = [
              "sh"
              "-c"
              "niri msg action focus-workspace --reference-workspace 1"
            ];
          }
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

        # Play-specific keybindings
        binds = with config.lib.niri.actions; {
          "Mod+Shift+t".action =
            spawn "firefox" "--new-window" "https://monkeytype.com";
        };

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
