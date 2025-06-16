{ config, pkgs, ... }:
let waybarStyle = builtins.readFile ./style_waybar.css;
in {
  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      position = "top";
      spacing = 0;
      height = 34;
      modules-left = [ "custom/logo" "sway/workspaces" "sway/mode" ];
      modules-center = [ "clock" "custom/notification" "tray" ];
      modules-right =
        [ "cpu" "memory" "network" "pulseaudio" "battery" "custom/power" ];

      "sway/workspaces" = {
        "on-click" = "activate";
        format = "{icon}";
        format-icons = {
          default = "";
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";

          active = "󱓻";
          urgent = "󱓻";
        };
        persistent_workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
        };
      };

      cpu = {
        interval = 5;
        format = "  {usage}%";
        states = {
          warning = 70;
          critical = 90;
        };
      };

      memory = {
        interval = 5;
        format = "  {}%";
        states = {
          warning = 70;
          critical = 90;
        };
      };

      tray = { spacing = 10; };

      clock = {
        interval = 1;
        format = "{:%I:%M, %e %b %Y}";
        "on-click" = "swaync-client -t -sw";
        "on-click-right" = "swaync-client -d -sw";
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

      "custom/logo" = {
        format = " 󱄅 ";
        tooltip = false;
        "on-click" = "fuzzel";
      };

      battery = {
        format = "{capacity}% {icon}";
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

      "custom/power" = {
        format = "󰤆";
        tooltip = false;
        "on-click" = "swaylock";
      };
    }];

    style = waybarStyle;
  };
  services.swayosd = { enable = true; };
}
