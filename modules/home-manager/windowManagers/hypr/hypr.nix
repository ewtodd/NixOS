{ lib, osConfig, ... }:
with lib;
let deviceType = osConfig.DeviceType;
in {
  imports = [
    #  ./hyprshell.nix
    ./plugins.nix
    ./launcher/rofi.nix
    ./settings/colors.nix
    ./settings/profile.nix
    ./services/swaync.nix
    ./services/wlogout.nix
    ./services/hypridle.nix
    ./services/hyprpaper.nix
    ./services/hyprsunset.nix
    ./services/hyprlock.nix
    ./services/avizo.nix
  ]
  # ++ optionals (deviceType == "laptop") [ ./settings/laptop.nix ]
    ++ optionals (deviceType == "framework") [ ./settings/framework.nix ]
    ++ optionals (deviceType == "desktop") [ ./settings/desktop.nix ];

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      package = osConfig.programs.hyprland.package;
      xwayland.enable = true;
      systemd.enable = false;

      settings = {

        "$terminal" = "kitty";
        "$menu" = "rofi -show drun -matching fuzzy | xargs swaymsg exec --";
        exec-once = [
          "blueman-applet"
          "udiskie --tray"
          "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
          "waybar"
        ];

        layerrule = [
          "blur, waybar"
          "blur, swaync-control-center"
          "blur, rofi"
          "blur, avizo"
        ];

        windowrule = [
          "float, class:(thunderbird), title:^Write:.*"
          "float, class:(org.pulseaudio.pavucontrol), title:Volume Control"
          "float, class:(floatingkitty)"
          "size 60% 60%, class:(thunderbird), title:^Write:.*"
          "size 60% 60%, class:(org.pulseaudio.pavucontrol), title:Volume Control"
          "size 60% 60%, class:(floatingkitty)"

        ];

        ecosystem = { no_update_news = true; };

        # General settings
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 3;
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
          rounding = 8;
          rounding_power = 2;
          active_opacity = 1.0;
          inactive_opacity = 1.0;

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 2;
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

        dwindle = {
          pseudotile = true;
          preserve_split = true;
          force_split = 2;
        };

        master = { new_status = "master"; };

        # Miscellaneous settings
        misc = {
          force_default_wallpaper = -1;
          disable_splash_rendering = true;
          disable_hyprland_logo = true;
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

          natural_scroll = true;
          touchpad = {
            natural_scroll = true;
            clickfinger_behavior = true;
          };
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
          "SUPER SHIFT, Return, exec, $terminal --class 'floatingkitty'"
          "SUPER SHIFT, q, killactive,"
          "SUPER, d, exec, $menu"

          # waybar
          "SUPER SHIFT, c, exec, pkill waybar && hyprctl dispatch exec waybar"

          # Firefox shortcuts
          "SUPER, f, exec, firefox"
          "SUPER SHIFT, p, exec, firefox --private-window"
          "SUPER, n, exec, firefox https://nix-community.github.io/nixvim/25.05/"
          "SUPER, p, exec, firefox --new-window -url https://search.nixos.org/packages -new-tab -url https://search.nixos.org/options? -new-tab -url https://home-manager-options.extranix.com/"
          "SUPER SHIFT, g, exec, firefox --private-window https://looptube.io/?videoId=eaPT0dQgS9E&start=0&end=4111&rate=1"

          # Lock screen 
          "ALT, l, exec, hyprlock"
          "SUPER, m, exec, wlogout -p layer-shell --buttons-per-row 2"

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
          "SUPER SHIFT, f, fullscreen"
          "SUPER, space, togglefloating"
          "SUPER, space, centerwindow"
          "SUPER SHIFT, space, centerwindow"

          # Notifications
          "SUPER SHIFT, n, exec, swaync-client -t"
          "SUPER SHIFT, e, exec, swaync-client --close-all"

          # Screenshots (using grimshot or grim + slurp)
          "ALT CTRL, 3, exec, grimshot copy output"
          "ALT CTRL, 4, exec, grimshot copy area"
          "ALT SHIFT CTRL, 3, exec, grimshot --notify save output"
          "ALT SHIFT CTRL, 4, exec, grimshot --notify save area"
        ];

        # Mouse bindings
        bindm =
          [ "SUPER, mouse:272, movewindow" "SUPER, mouse:273, resizewindow" ];

        # Volume and brightness controls using brightnessctl
        binde = [
          ",XF86AudioRaiseVolume, exec, volumectl -u up"
          ",XF86AudioLowerVolume, exec, volumectl -u down"
          ",XF86AudioMute, exec, volumectl toggle-mute"
          ",XF86MonBrightnessUp, exec, lightctl up"
          ",XF86MonBrightnessDown, exec, lightctl down"
          ",F8, exec, lightctl up"
          ",F7, exec, lightctl down"
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
