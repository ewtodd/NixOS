{ config, pkgs, lib, osConfig, ... }:
with lib;
let deviceType = osConfig.DeviceType;
in {
  imports = [
    ./settings/sway-colors.nix
    ./settings/profile.nix
    ./services/swayidle.nix
    ./services/swaync.nix
    ./services/swaylock.nix
    ./services/wlogout.nix
    ./services/swayosd.nix
    ./launcher/rofi.nix
  ] ++ optionals (deviceType == "laptop") [ ./settings/laptop.nix ]
    ++ optionals (deviceType == "desktop") [ ./settings/desktop.nix ];

  config = let
    colors = config.colorScheme.palette;
    profile = config.Profile;
    fontFamily = if profile == "work" then
      "FiraCode Nerd Font"
    else
      "JetBrains Mono Nerd Font";

  in {
    wayland.windowManager.sway = {
      enable = true;
      package = null;
      wrapperFeatures.gtk = true;
      xwayland = true;
      config = {
        workspaceLayout = "default";

        # Variables
        modifier = "Mod4";
        terminal = "kitty";
        menu = "rofi -show drun -matching fuzzy | xargs swaymsg exec --";

        # Direction keys (vim-style)
        left = "h";
        down = "j";
        up = "k";
        right = "l";

        # Window appearance
        window = {
          border = 1;
          titlebar = false;
        };

        gaps = {
          inner = 2;
          outer = 2;
          smartBorders = "on";
        };

        # Font - now dynamic based on profile
        fonts = {
          names = [ fontFamily ];
          size = 12.0;
        };

        keybindings = {
          # Basic window management
          "Mod4+Return" =
            "exec ${config.wayland.windowManager.sway.config.terminal}";
          "Mod4+Shift+q" = "kill";
          "Mod4+Tab" = "exec swayr switch-window";
          "Mod4+grave" =
            "exec swayr switch-to-urgent-or-lru-window"; # backtick key
          "Mod4+Shift+Tab" = "exec swayr switch-workspace";
          "Mod4+Delete" = "exec swayr quit-window";
          "Mod4+d" = "exec ${config.wayland.windowManager.sway.config.menu}";
          "Mod4+f" = "exec firefox";
          "Mod4+Shift+p" = "exec firefox --private-window";
          "Mod1+n" =
            "exec firefox https://nix-community.github.io/nixvim/25.05/";
          "Mod4+p" =
            "exec firefox --new-window -url https://search.nixos.org/packages -new-tab -url https://search.nixos.org/options? -new-tab -url https://home-manager-options.extranix.com/";
          "Mod4+k+l" = "exec ${pkgs.swaylock-effects}/bin/swaylock";
          "Mod4+h" = "exec papersway-msg focus left";
          "Mod4+j" = "focus down";
          "Mod4+k" = "focus up";
          "Mod4+l" = "exec papersway-msg focus right";
          "Mod4+Left" = "exec papersway-msg focus left";
          "Mod4+Down" = "focus down";
          "Mod4+Up" = "focus up";
          "Mod4+Right" = "exec papersway-msg focus right";
          # Window management
          "Mod1+f" = "exec papersway-msg width toggle";
          "Mod4+o" = "exec papersway-msg other-column";

          # Workspace management
          "Mod4+a" = "exec papersway-msg fresh-workspace";
          "Mod4+n" = "exec papersway-msg fresh-workspace send";
          "Mod4+t" = "exec papersway-msg fresh-workspace take";
          "Mod4+b" = "exec papersway-msg bury-workspace";

          # Column operations
          "Mod4+e" = "exec papersway-msg absorb-expel left";
          "Mod4+r" = "exec papersway-msg absorb-expel right";
          "Mod4+minus" = "exec papersway-msg cols decr";
          "Mod4+equal" = "exec papersway-msg cols incr";

          # Workspace navigation
          "Mod4+u" = "exec papersway-msg workspace prev";
          "Mod4+i" = "exec papersway-msg workspace next";
          "Mod4+Shift+u" = "exec papersway-msg move-to-workspace prev";
          "Mod4+Shift+i" = "exec papersway-msg move-to-workspace next";

          # Caffeine mode (idle inhibition)
          "Mod4+c" =
            "[con_mark=caffeinated] inhibit_idle none; inhibit_idle open, mark caffeinated";
          "Mod4+Mod1+c" =
            "[con_mark=caffeinated] inhibit_idle none, mark --toggle caffeinated";
          # Move windows
          "Mod4+Shift+h" = "exec papersway-msg move left";
          "Mod4+Shift+j" = "move down";
          "Mod4+Shift+k" = "move up";
          "Mod4+Shift+l" = "exec papersway-msg move right";
          "Mod4+Shift+Left" = "exec papersway-msg move left";
          "Mod4+Shift+Down" = "move down";
          "Mod4+Shift+Up" = "move up";
          "Mod4+Shift+Right" = "exec papersway-msg move right";

          # Troubleshooting!
          "Mod4+Shift+Return" =
            "exec swaymsg -r -t get_outputs | jq '.[0].layer_shell_surfaces | .[] | .namespace' | xargs notify-send";

          # Layout management

          # System controls
          "Mod4+Shift+c" = "reload";
          "Mod4+Shift+e" = "exec swaync-client --close-all";
          "Mod4+m" =
            "exec ${pkgs.wlogout}/bin/wlogout -p layer-shell --buttons-per-row 2";

          # Notifications
          "Mod4+Shift+n" = "exec swaync-client -t -sw";

          # Screenshots
          "Mod1+control+3" = "exec grimshot copy output";
          "Mod1+control+4" = "exec grimshot copy area";
          "Mod1+Shift+control+3" = "exec grimshot --notify save output";
          "Mod1+Shift+control+4" = "exec grimshot --notify save area";

          "XF86AudioRaiseVolume" = "exec swayosd-client --output-volume raise";
          "XF86AudioLowerVolume" = "exec swayosd-client --output-volume lower";
          "XF86AudioMute" = "exec swayosd-client --output-volume mute-toggle";
          "XF86AudioMicMute" = "exec swayosd-client --input-volume mute-toggle";

          # Brightness controls with SwayOSD (for laptops)
          "XF86MonBrightnessUp" = "exec swayosd-client --brightness raise";
          "XF86MonBrightnessDown" = "exec swayosd-client --brightness lower";

          # Caps lock indicator
          "Caps_Lock" = "exec swayosd-client --caps-lock";

          # papersway 
          "Mod4 + a" = "exec papersway-msg fresh-workspace";
        };

        # Resize mode
        modes = {
          resize = {
            "h" = "resize shrink width 10px";
            "j" = "resize grow height 10px";
            "k" = "resize shrink height 10px";
            "l" = "resize grow width 10px";
            "Left" = "resize shrink width 10px";
            "Down" = "resize grow height 10px";
            "Up" = "resize shrink height 10px";
            "Right" = "resize grow width 10px";
            "Return" = "mode default";
            "Escape" = "mode default";
          };
        };
        bars = [{
          position = "bottom";
          statusCommand = "papersway --i3status";
        }];

        input = {
          "type:touchpad" = mkIf (deviceType == "laptop") {
            tap = "enabled";
            natural_scroll = "enabled";
            tap_button_map = "lrm";
          };
          "type:pointer" = { natural_scroll = "enabled"; };
        };
        focus.wrapping = "no";
        window.commands = [{
          criteria = { con_mark = "caffeinated"; };
          command = "inhibit_idle open";
        }];
      };

      extraConfig = ''
        blur enable
        blur_passes 3
        blur_radius 2
        blur_contrast 1.0

        smart_corner_radius on
        corner_radius 15

        shadows enable
        shadows_on_csd enable
        shadow_blur_radius 30
        shadow_color #${colors.base00}99
        shadow_inactive_color #${colors.base00}55

        default_dim_inactive 0.15
        dim_inactive_colors.unfocused #${colors.base00}
        dim_inactive_colors.urgent #${colors.base08}

        for_window [app_id="firefox"] saturation set 1.1
        for_window [app_id="spotify"] saturation set 1.2
        for_window [class=".*"] inhibit_idle fullscreen
        for_window [app_id=".*"] inhibit_idle fullscreen

        layer_effects "swaync-control-center" blur enable; shadows enable
        layer_effects "rofi" blur enable; shadows enable
        layer_effects "waybar" blur enable; shadows enable
        layer_effects "gtk-layer-shell" blur enable; shadows enable
        layer_effects "logout_dialog" blur enable

        exec waybar 
        exec swayrd
        exec udiskie --tray
        exec gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
      '' + lib.optionalString (profile == "play") ''
        exec gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-dark-purple'
      '' + lib.optionalString (profile == "work") ''
        exec gsettings set org.gnome.desktop.interface gtk-theme 'Kanagawa-B-LB'
      '';
    };
  };
}
