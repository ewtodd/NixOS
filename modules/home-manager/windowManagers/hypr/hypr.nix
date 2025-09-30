{ config, pkgs, lib, osConfig, ... }:
with lib;
let
  deviceType = osConfig.DeviceType;
  wallpaperPath = config.WallpaperPath;
  primaryMonitor = if osConfig.DeviceType == "desktop" then "DP-3" else "eDP-1";
  secondaryMonitor =
    if osConfig.DeviceType == "desktop" then "HDMI-A-1" else "HDMI-A-2";
in {
  imports =
    [ ./settings/colors.nix ./services/hypridle.nix ./services/hyprlock.nix ];
  # ++ optionals (deviceType == "laptop") [ ./settings/laptop.nix ]
  # ++ optionals (deviceType == "framework") [ ./settings/framework.nix ]
  # ++ optionals (deviceType == "desktop") [ ./settings/desktop.nix ];

  config = let colors = config.colorScheme.palette;
  in {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      xwayland.enable = true;
      systemd.enable = false;

      settings = {

        "$left" = "h";
        "$down" = "j";
        "$up" = "k";
        "$right" = "l";

        # Monitor configuration
        monitor = "eDP-1,2256x1504@59.999,0x0,1.333333";
        # Program variables
        "$terminal" = "kitty";
        "$fileManager" = "dolphin";
        "$menu" = "wofi --show drun";
        "$mainMod" = "SUPER";

        # Environment variables
        env = [ "XCURSOR_SIZE,24" "HYPRCURSOR_SIZE,24" ];

        # Autostart programs (uncomment as needed)
        # exec-once = [
        #   "$terminal"
        #   "nm-applet &"
        #   "waybar & hyprpaper & firefox"
        # ];

        # General settings
        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        # Decoration settings
        decoration = {
          rounding = 10;
          rounding_power = 2;
          active_opacity = 1.0;
          inactive_opacity = 1.0;

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };

        # Animation settings
        animations = {
          enabled = true;

          bezier = [
            "easeOutQuint, 0.23, 1, 0.32, 1"
            "easeInOutCubic, 0.65, 0.05, 0.36, 1"
            "linear, 0, 0, 1, 1"
            "almostLinear, 0.5, 0.5, 0.75, 1"
            "quick, 0.15, 0, 0.1, 1"
          ];

          animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 4.79, easeOutQuint"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "windowsOut, 1, 1.49, linear, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 1, 1.94, almostLinear, fade"
            "workspacesIn, 1, 1.21, almostLinear, fade"
            "workspacesOut, 1, 1.94, almostLinear, fade"
            "zoomFactor, 1, 7, quick"
          ];
        };

        # Layout settings
        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master = { new_status = "master"; };

        # Miscellaneous settings
        misc = {
          force_default_wallpaper = -1;
          disable_hyprland_logo = false;
        };

        # Input settings
        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";
          follow_mouse = 1;
          sensitivity = 0;

          touchpad = { natural_scroll = true; };
        };

        # Gestures
        gesture = "3, horizontal, workspace";

        # Per-device configuration
        device = {
          name = "epic-mouse-v1";
          sensitivity = -0.5;
        };

        bind = [
          # Basic window management
          "SUPER, Return, exec, $terminal"
          "SUPER SHIFT, q, killactive,"
          "SUPER, d, exec, $menu"

          # Firefox shortcuts
          "SUPER, f, exec, firefox"
          "SUPER SHIFT, p, exec, firefox --private-window"
          "SUPER, n, exec, firefox https://nix-community.github.io/nixvim/25.05/"
          "SUPER, p, exec, firefox --new-window -url https://search.nixos.org/packages -new-tab -url https://search.nixos.org/options? -new-tab -url https://home-manager-options.extranix.com/"
          "SUPER SHIFT, g, exec, firefox --private-window https://looptube.io/?videoId=eaPT0dQgS9E&start=0&end=4111&rate=1"

          # Lock screen (using swaylock or similar)

          # Focus movement (hjkl keys)
          "SUPER, h, movefocus, l"
          "SUPER, j, movefocus, d"
          "SUPER, k, movefocus, u"
          "SUPER, l, movefocus, r"

          # Focus movement (arrow keys)
          "SUPER, left, movefocus, l"
          "SUPER, down, movefocus, d"
          "SUPER, up, movefocus, u"
          "SUPER, right, movefocus, r"

          # Move windows (hjkl keys)
          "SUPER SHIFT, h, movewindow, l"
          "SUPER SHIFT, j, movewindow, d"
          "SUPER SHIFT, k, movewindow, u"
          "SUPER SHIFT, l, movewindow, r"

          # Move windows (arrow keys)
          "SUPER SHIFT, left, movewindow, l"
          "SUPER SHIFT, down, movewindow, d"
          "SUPER SHIFT, up, movewindow, u"
          "SUPER SHIFT, right, movewindow, r"

          # Workspaces
          "SUPER, 1, workspace, 1"
          "SUPER, 2, workspace, 2"
          "SUPER, 3, workspace, 3"
          "SUPER, 4, workspace, 4"
          "SUPER, 5, workspace, 5"
          "SUPER, 6, workspace, 6"
          "SUPER, 7, workspace, 7"
          "SUPER, 8, workspace, 8"
          "SUPER, 9, workspace, 9"
          "SUPER, 0, workspace, 10"

          # Move to workspaces
          "SUPER SHIFT, 1, movetoworkspace, 1"
          "SUPER SHIFT, 2, movetoworkspace, 2"
          "SUPER SHIFT, 3, movetoworkspace, 3"
          "SUPER SHIFT, 4, movetoworkspace, 4"
          "SUPER SHIFT, 5, movetoworkspace, 5"
          "SUPER SHIFT, 6, movetoworkspace, 6"
          "SUPER SHIFT, 7, movetoworkspace, 7"
          "SUPER SHIFT, 8, movetoworkspace, 8"
          "SUPER SHIFT, 9, movetoworkspace, 9"
          "SUPER SHIFT, 0, movetoworkspace, 10"

          # Layout management
          "SUPER SHIFT, f, fullscreen,"
          "SUPER SHIFT, space, togglefloating,"
          "SUPER, space, focusurgentorlast," # Closest equivalent to focus mode_toggle
          "SUPER, a, focusmonitor, +1" # Focus parent equivalent (focus next monitor)

          # Scratchpad (special workspace in Hyprland)
          "SUPER SHIFT, minus, movetoworkspace, special:scratchpad"
          "SUPER, minus, togglespecialworkspace, scratchpad"

          # System controls
          "SUPER SHIFT, c, exec, hyprctl reload"
          "SUPER, m, exec, wlogout -p layer-shell --buttons-per-row 2"
          "SUPER, r, submap, resize" # Enter resize mode

          # Notifications (using mako/dunst instead of swaync)
          "SUPER SHIFT, n, exec, makoctl dismiss"
          "SUPER SHIFT, e, exec, makoctl dismiss --all"

          # Screenshots (using grimshot or grim + slurp)
          "ALT CTRL, 3, exec, grimshot copy output"
          "ALT CTRL, 4, exec, grimshot copy area"
          "ALT SHIFT CTRL, 3, exec, grimshot --notify save output"
          "ALT SHIFT CTRL, 4, exec, grimshot --notify save area"

          # Workspace scrolling
          "SUPER, mouse_down, workspace, e+1"
          "SUPER, mouse_up, workspace, e-1"

          # Troubleshooting (Hyprland equivalent)
          ''
            SUPER SHIFT, Return, exec, notify-send "$(hyprctl clients -j | jq '.[].class' | head -5)"''
        ];

        # Mouse bindings
        bindm =
          [ "SUPER, mouse:272, movewindow" "SUPER, mouse:273, resizewindow" ];

        # Volume and brightness controls using brightnessctl
        bindel = [
          ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, brightnessctl set 5%+"
          ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
          ",F8, exec, brightnessctl set 5%+"
          ",F7, exec, brightnessctl set 5%-"
        ];

        # Media controls (requires playerctl)
        bindl = [
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ];
      };
    };
  };
}
