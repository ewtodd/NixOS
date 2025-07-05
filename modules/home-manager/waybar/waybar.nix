{ config, pkgs, lib, osConfig, ... }:
with lib;

let
  windowManager = osConfig.WindowManager;
  deviceType = osConfig.DeviceType;
  profile = config.Profile;
in {
  imports = [ ./style.nix ];

  config = mkIf config.programs.waybar.enable {
    programs.waybar = {
      settings = [{
        layer = "bottom";
        position = "top";
        spacing = 0;
        height = 34;
        modules-left =
          [ "${windowManager}/workspaces" "${windowManager}/window" ]
          ++ optionals (windowManager != "niri") [ "${windowManager}/mode" ];
        modules-center = [ "clock" "tray" ];
        modules-right = [ "cpu" "memory" "network" "pulseaudio" ]
          ++ optionals (deviceType == "laptop") [ "battery" ]
          ++ [ "custom/notification" ];
        "${windowManager}/window" = mkIf (windowManager != "niri") {
          format = "";
          max-length = 0;
        };

        "${windowManager}/mode" =
          mkIf (windowManager != "niri") { format = "{}"; };
        "${windowManager}/workspaces" = if windowManager == "niri" then {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            default = "";
            "slack" = "";
            "thunderbird" = "";
            "signal" = "󰿌";
            "steam" = "";
            "spotify" = "";
          };
        } else {
          "on-click" = "activate";
          format = "{name}";
          format-icons = {
            "1" = "󰇊";
            "2" = "󰇋";
            "3" = "󰇌";
            "4" = "󰇍";
            "5" = "󰇎";
            "6" = "󰇏";
            "7" = if (profile == "work") then "" else "󰿌";
            "8" = "";
            "9" = if (profile == "play") then "" else "";
            "10" = if (profile == "play") then "" else "";
          };
        };
        cpu = {
          interval = 5;
          format = "{icon} {usage}%";
          format-icons = "";
          states = {
            warning = 70;
            critical = 90;
          };
        };

        memory = {
          interval = 5;
          format = "{icon} {}%";
          format-icons = "";
          states = {
            warning = 70;
            critical = 90;
          };
        };

        tray = { spacing = 10; };

        clock = {
          interval = 1;
          format = "{:%I:%M, %d %b %Y}";
          tooltip = false;
        };

        "custom/notification" = {
          tooltip = false;
          format = "{icon} {text}";
          format-icons = {
            notification = "󰂚";
            none = "󰂜";
            dnd-notification = "󰂛";
            dnd-none = "󰪑";
          };

          return-type = "json";
          exec-if = "which makoctl";
          exec = pkgs.writeShellScript "mako-waybar" ''
            #!/bin/bash

            # Get current pending notifications (for immediate display)
            current_count=$(makoctl list | jq '.data | length' 2>/dev/null || echo "0")

            # Get recent history count (last 10 notifications from today)
            history_count=$(makoctl history | grep -c "Notification [0-9]*:" 2>/dev/null || echo "0")

            # Use current count if there are pending notifications, otherwise show nothing
            notification_count="$current_count"

            # Get current mode
            mode_output=$(makoctl mode 2>/dev/null || echo "")

            # Check if DND mode is active
            if echo "$mode_output" | grep -q "dnd"; then
              mode="dnd"
            else
              mode="default"
            fi

            # Determine icon and text based on mode and count
            if [[ "$mode" == "dnd" ]]; then
              if [[ "$notification_count" -gt 0 ]]; then
                icon="dnd-notification"
                text="$notification_count (DND)"
              else
                icon="dnd-none"
                text="DND"
              fi
            else
              if [[ "$notification_count" -gt 0 ]]; then
                icon="notification"
                text="$notification_count"
              else
                icon="none"
                text=""
              fi
            fi

            # Get latest notification from current list, fallback to history
            if [[ "$current_count" -gt 0 ]]; then
              latest_summary=$(makoctl list | jq -r '.data[0].summary.data // "No notifications"' 2>/dev/null || echo "No notifications")
            else
              # Parse latest from history (text format)
              latest_summary=$(makoctl history | head -20 | grep -A2 "Notification [0-9]*:" | head -1 | cut -d':' -f2- | xargs 2>/dev/null || echo "No recent notifications")
            fi

            # Output JSON for waybar
            printf '{"text":"%s","icon":"%s","tooltip":"%s","class":"%s"}\n' \
              "$text" "$icon" "$latest_summary" "$mode"
          '';
          on-click = "makoctl dismiss --all";
          on-click-right = "makoctl mode -t dnd";
          on-click-middle = "makoctl restore";
          escape = true;
          interval = 2;
        };

        network = {
          "format-wifi" = "{icon}";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
          "format-ethernet" = "󰀂";
          "format-disconnected" = "󰖪";
          "tooltip-format-wifi" = ''
            {icon} {essid}
            ⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}'';
          "tooltip-format-ethernet" = ''
            󰀂  {ifname}
            ⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}'';
          "tooltip-format-disconnected" = "Disconnected";
          "on-click" = "kitty 'nmtui'";
          interval = 5;
          nospacing = 1;
        };

        pulseaudio = {
          "scroll-step" = 1;
          format = "{icon} {volume}%";
          "format-bluetooth" = "󰂰";
          nospacing = 1;
          "tooltip-format" = "Volume : {volume}%";
          "format-muted" = "󰝟";
          "format-icons" = {
            headphone = "";
            default = [ "󰖀" "󰕾" " " ];
          };
          "on-click" = "pavucontrol";
          "on-scroll-up" = "pactl set-sink-volume @DEFAULT_SINK@ +2%";
          "on-scroll-down" = "pactl set-sink-volume @DEFAULT_SINK@ -2%";
        };

        battery = {
          format = "{icon} {capacity}%";
          "format-icons" = {
            charging = [ "󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" ];
            default = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          };
          "format-full" = "Charged ";
          interval = 5;
          states = {
            warning = 20;
            critical = 10;
          };
          tooltip = false;
        };

      }];
    };
  };
}
