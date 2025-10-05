{ config, lib, osConfig, pkgs, ... }:
with lib;

let
  windowManager = osConfig.WindowManager;
  deviceType = osConfig.DeviceType;
in {
  imports = [ ./style.nix ];

  config = mkIf config.programs.waybar.enable {
    programs.waybar = {
      settings = [{
        layer = "bottom";
        position = "top";
        spacing = 0;
        height = 34;
        modules-left = [ "custom/notification" "group/left" ];
        modules-center = [
          "${windowManager}/workspaces"
          "${windowManager}/window"
          "${windowManager}/mode"
        ];
        modules-right = [ "custom/cpu" "memory" ]
          ++ optionals (deviceType == "desktop") [
            "custom/gpu"
            "custom/gpumemory"
          ] ++ optionals (deviceType != "desktop") [ "battery" ];
        "${windowManager}/window" = {
          format = "";
          max-length = 0;
        };

        "${windowManager}/workspaces" = {
          "on-click" = "activate";
          format = "{name}";
        };

        "custom/cpu" = {
          exec = "${pkgs.writeShellScript "cpu-stats.sh" ''
            cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.f%%", 100 - $1}')
            cpu_temp=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Package id 0:" | ${pkgs.gawk}/bin/awk '{gsub(/[^0-9.]/, "", $4); printf "%.0f", $4}')
            cpu_freq=$(cat /proc/cpuinfo | grep "cpu MHz" | head -n1 | awk '{printf "%.1fGHz", $4/1000}')
            echo "''${cpu_usage} ''${cpu_temp}°C ''${cpu_freq}"
          ''}";
          interval = 3;
          format = "{icon} {}";
          format-icons = "";
        };

        "custom/gpu" = {
          interval = 3;
          exec = ''
            echo " $(nvtop -s 2>/dev/null | jq -r '.[0] | "\(.gpu_util) \(.temp | gsub("C"; "°C")) \(.gpu_clock)"')"'';
        };
        "custom/gpumemory" = {
          interval = 3;
          exec = ''echo "󰘚 $(nvtop -s 2>/dev/null | jq -r ".[0].mem_util")"'';
        };

        memory = {
          interval = 3;
          format = "{icon} {}%";
          format-icons = "";
          states = {
            warning = 70;
            critical = 90;
          };
        };

        "group/left" = {
          orientation = "inherit";
          drawer = { transition-duration = 200; };
          modules = [ "clock" "network" "pulseaudio" "power-profiles-daemon" ]
            ++ [ "tray" ];
        };

        tray = { spacing = 10; };

        clock = {
          interval = 1;
          format = "{:%I:%M, %d %b %Y}";
          tooltip = false;
        };

        "custom/notification" = {
          tooltip = false;
          format = "{icon}";
          format-icons = {
            notification = "<span foreground='red'><sup></sup></span>";
            none = "";
            dnd-notification = "<span foreground='red'><sup></sup></span>";
            dnd-none = "";
            inhibited-notification =
              "<span foreground='red'><sup></sup></span>";
            inhibited-none = "";
            dnd-inhibited-notification =
              "<span foreground='red'><sup></sup></span>";
            dnd-inhibited-none = "";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
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
          "on-click" = "kitty --class 'floatingkitty' 'nmtui'";
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
        power-profiles-daemon = {
          "format" = "{icon}";
          "tooltip-format" = "Power profile = {profile}";
          "tooltip" = true;
          "format-icons" = {
            "default" = "";
            "performance" = "";
            "balanced" = "";
            "power-saver" = "";
          };
        };
      }];
    };
  };
}
