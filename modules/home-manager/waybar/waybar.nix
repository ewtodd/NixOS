{ config, lib, osConfig, ... }:
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
        modules-left = [
          "${windowManager}/workspaces"
          "${windowManager}/window"
          "${windowManager}/mode"
        ];
        modules-center = [ "clock" "tray" ];
        modules-right = [ "cpu" ] ++ optionals (deviceType == "desktop") [
          "custom/gpu"
          "custom/gpumemory"
        ] ++ [ "memory" "network" "pulseaudio" ]
          ++ optionals (deviceType == "laptop") [ "battery" ]
          ++ [ "custom/notification" ];
        "${windowManager}/window" = {
          format = "";
          max-length = 0;
        };

        "${windowManager}/workspaces" = {
          "on-click" = "activate";
          format = "{name}";
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

        "custom/gpu" = {
          interval = 5;
          exec = ''echo " $(nvtop -s 2>/dev/null | jq -r ".[0].gpu_util")"'';
        };
        "custom/gpumemory" = {
          interval = 5;
          exec = ''echo "󰘚 $(nvtop -s 2>/dev/null | jq -r ".[0].mem_util")"'';
        };

        memory = {
          interval = 5;
          format = "{icon} {}%";
          format-icons = "";
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
          "on-click" = "pavucontrol-qt";
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
