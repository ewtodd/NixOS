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
