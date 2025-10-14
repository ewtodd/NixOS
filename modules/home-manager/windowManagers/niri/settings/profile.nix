{ config, lib, osConfig, ... }:

{
  programs.niri.enable = true;

  programs.niri.settings = lib.mkMerge [
    (lib.mkIf (config.Profile == "work") {
      keybindings = {
        "Mod4+g" = {
          action = "spawn firefox --new-window -url https://umgpt.umich.edu/";
        };
      };
    })
    (lib.mkIf (config.Profile == "play") {
      keybindings = {
        "Mod4+Shift+t" = {
          action = "spawn firefox --new-window https://monkeytype.com";
        };
      };
    })
  ];
}
