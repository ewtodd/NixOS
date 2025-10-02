{ config, lib, osConfig, ... }:

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
      wayland.windowManager.hyprland = {
        settings = {
          # Window rules for assigns (equivalent to sway assigns)
          windowrulev2 = [
            # Workspace 3 assignments
          ] ++ optionals (osConfig.DeviceType != "desktop")
            [ "workspace 3, class:(Slack)" ]
            ++ optionals (osConfig.DeviceType == "desktop")
            [ "workspace 3, class:(Todoist)" ] ++ [
              # Workspace 4 assignments  
            ] ++ optionals (osConfig.DeviceType != "desktop")
            [ "workspace 4, class:(Todoist)" ] ++ [
              # Workspace 2 assignments
              "workspace 2, class:(thunderbird)"
            ] ++ optionals (osConfig.DeviceType == "desktop")
            [ "workspace 2, class:(Slack)" ];

          # Workspace monitor assignments
          workspace = [
            "1, monitor:${primaryMonitor}, default:true"
            "2, monitor:${primaryMonitor}"
            "3, monitor:${primaryMonitor}"
            "4, monitor:${primaryMonitor}"
            "5, monitor:${secondaryMonitor}, default:true"
            "6, monitor:${secondaryMonitor}"
          ];

          # Work-specific keybindings
          bind =
            [ "SUPER, g, exec, firefox --new-window https://umgpt.umich.edu/" ];

          # Startup applications
          exec-once = [
            "thunderbird"
            "slack"
            "todoist-electron --enable-features=UseOzonePlatform --ozone-platform=wayland"
            "sleep 2 && hyprctl dispatch workspace 1"
          ];
        };
      };
    })

    (mkIf (config.Profile == "play") {
      wayland.windowManager.hyprland = {
        settings = {
          # Window rules for assigns
          windowrulev2 = [
            "workspace 2, class:(steam)"
            "workspace 3, class:(spotify)"
            "workspace 5, class:(signal)"
          ];

          # Workspace monitor assignments  
          workspace = [
            "1, monitor:${primaryMonitor}, default:true"
            "2, monitor:${primaryMonitor}"
            "3, monitor:${primaryMonitor}"
            "4, monitor:${primaryMonitor}"
            "5, monitor:${secondaryMonitor}, default:true"
            "6, monitor:${secondaryMonitor}"
          ];

          # Play-specific keybindings
          bind = [
            "SUPER SHIFT, t, exec, firefox --new-window https://monkeytype.com"
          ];

          # Startup applications
          exec-once = [
            "steam"
            "spotify"
            "sleep 2 && signal-desktop --use-tray-icon"
            "sleep 2 && hyprctl dispatch workspace 1"
          ];
        };
      };
    })
  ];
}
