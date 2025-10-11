{ config, pkgs, lib, osConfig, ... }:
with lib;
let
  deviceType = osConfig.DeviceType;
  wallpaperPath = config.WallpaperPath;
  fontFamily = config.FontChoice;
  toggle-float-smart = pkgs.writeShellScript "toggle-float-smart" ''
    # Get the focused window's floating state
    floating=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | select(.focused? == true) | .floating')

    if [ "$floating" = "user_on" ] || [ "$floating" = "auto_on" ]; then
        # If already floating, just toggle (disable floating)
        ${pkgs.sway}/bin/swaymsg floating toggle
    else
        # If tiled, enable floating, resize, and center
        ${pkgs.sway}/bin/swaymsg floating enable, resize set 75 ppt 75 ppt, move position center
    fi
  '';
in {
  imports = [
    ./settings/sway-colors.nix
    ./services/swayidle.nix
    ./services/swaync.nix
    ./services/swaylock.nix
    ./services/avizo.nix
    ./services/wlogout.nix
    ./launcher/rofi.nix
  ] ++ optionals (deviceType == "laptop") [ ./settings/laptop.nix ]
    ++ optionals (deviceType == "desktop") [ ./settings/desktop.nix ];

  config = let colors = config.colorScheme.palette;
  in {
    wayland.windowManager.sway = {
      enable = true;
      package = null;
      wrapperFeatures.gtk = true;
      xwayland = true;

      config = {
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
          border = 3;
          titlebar = false;
        };

        gaps = {
          inner = 2;
          outer = 2;
          smartBorders = "on";
        };

        fonts = {
          names = [ "${fontFamily}" ];
          size = 12.0;
        };

        keybindings = {
          # Basic window management
          "Mod4+Return" =
            "exec ${config.wayland.windowManager.sway.config.terminal}";
          "Mod4+Shift+Return" =
            "exec ${config.wayland.windowManager.sway.config.terminal} --class 'floatingkitty'";
          "Mod4+Shift+q" = "kill";
          "Mod4+d" = "exec ${config.wayland.windowManager.sway.config.menu}";
          "Mod4+Shift+d" =
            "exec rofi -show filebrowser -matchine fuzzy -filebrowser-directory ~";

          "Mod4+f" = "exec firefox";
          "Mod4+Shift+p" = "exec firefox --private-window";
          "Mod4+n" =
            "exec firefox https://nix-community.github.io/nixvim/25.05/";
          "Mod4+p" =
            "exec firefox --new-window -url https://search.nixos.org/packages -new-tab -url https://search.nixos.org/options? -new-tab -url https://home-manager-options.extranix.com/";
          "Mod4+Shift+g" =
            "exec firefox --private-window https://looptube.io/?videoId=eaPT0dQgS9E&start=0&end=4111&rate=1";
          "Mod1+l" = "exec ${pkgs.swaylock-effects}/bin/swaylock";
          "Mod4+h" = "focus left";
          "Mod4+j" = "focus down";
          "Mod4+k" = "focus up";
          "Mod4+l" = "focus right";
          "Mod4+Left" = "focus left";
          "Mod4+Down" = "focus down";
          "Mod4+Up" = "focus up";
          "Mod4+Right" = "focus right";

          # Move windows
          "Mod4+Shift+h" = "move left";
          "Mod4+Shift+j" = "move down";
          "Mod4+Shift+k" = "move up";
          "Mod4+Shift+l" = "move right";
          "Mod4+Shift+Left" = "move left";
          "Mod4+Shift+Down" = "move down";
          "Mod4+Shift+Up" = "move up";
          "Mod4+Shift+Right" = "move right";

          # Workspaces
          "Mod4+1" = "workspace number 1";
          "Mod4+2" = "workspace number 2";
          "Mod4+3" = "workspace number 3";
          "Mod4+4" = "workspace number 4";
          "Mod4+5" = "workspace number 5";
          "Mod4+6" = "workspace number 6";
          "Mod4+7" = "workspace number 7";
          "Mod4+8" = "workspace number 8";
          "Mod4+9" = "workspace number 9";
          "Mod4+0" = "workspace number 10";

          # Move to workspaces
          "Mod4+Shift+1" = "move container to workspace number 1";
          "Mod4+Shift+2" = "move container to workspace number 2";
          "Mod4+Shift+3" = "move container to workspace number 3";
          "Mod4+Shift+4" = "move container to workspace number 4";
          "Mod4+Shift+5" = "move container to workspace number 5";
          "Mod4+Shift+6" = "move container to workspace number 6";
          "Mod4+Shift+7" = "move container to workspace number 7";
          "Mod4+Shift+8" = "move container to workspace number 8";
          "Mod4+Shift+9" = "move container to workspace number 9";
          "Mod4+Shift+0" = "move container to workspace number 10";

          # Layout management
          "Mod4+Shift+f" = "fullscreen";
          "Mod4+space" = "exec ${toggle-float-smart}";
          "Mod4+Shift+space" = "move position center";

          # System controls
          "Mod4+Shift+c" = "reload";
          "Mod4+m" =
            "exec ${pkgs.wlogout}/bin/wlogout -p layer-shell --buttons-per-row 2";
          "Mod4+r" = "mode resize";

          # Replace SwayNC keybindings with Mako
          "Mod4+Shift+n" = "exec swaync-client -t";
          "Mod4+Shift+e" = "exec swaync-client --close-all";

          # Screenshots
          "Mod1+control+3" = "exec grimshot copy output";
          "Mod1+control+4" = "exec grimshot copy area";
          "Mod1+Shift+control+3" = "exec grimshot --notify save output";
          "Mod1+Shift+control+4" = "exec grimshot --notify save area";

          "XF86AudioRaiseVolume" = "exec volumectl -u up";
          "XF86AudioLowerVolume" = "exec volumectl -u down";
          "XF86AudioMute" = "exec volumectl toggle-mute";

          "XF86MonBrightnessUp" = "exec lightctl up";
          "XF86MonBrightnessDown" = "exec lightctl down";
          "F8" = "exec lightctl up";
          "F7" = "exec lightctl down";

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
          position = "top";
          command = "waybar";
        }];

        input = {
          "type:touchpad" = mkIf (deviceType != "desktop") {
            tap = "enabled";
            natural_scroll = "enabled";
            tap_button_map = "lrm";
          };
          "type:pointer" = { natural_scroll = "enabled"; };
        };
      };

      extraConfig = ''
        blur enable
        blur_passes 3
        blur_radius 2
        blur_contrast 1.0

        smart_corner_radius on
        corner_radius 10

        shadows enable
        shadows_on_csd enable
        shadow_blur_radius 30
        shadow_color #${colors.base00}99
        shadow_inactive_color #${colors.base00}55

        default_dim_inactive 0.15
        dim_inactive_colors.unfocused #${colors.base00}
        dim_inactive_colors.urgent #${colors.base08}

        layer_effects "rofi" blur enable; shadows enable
        layer_effects "avizo" blur enable; shadows enable
        layer_effects "gtk-layer-shell" blur enable; shadows enable
        layer_effects "logout_dialog" blur enable; shadows enable 
        layer_effects "swaync-control-center" blur enable; shadows enable

        exec swaybg -i ${wallpaperPath}
        exec slueman-applet
        exec udiskie --tray
        exec gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        exec swaymsg workspace 1



        # Thunderbird compose window
        for_window [app_id="thunderbird" title="^Write:"] floating enable, resize set 75 ppt 75 ppt, move position center

        # PulseAudio volume control
        for_window [title="Volume Control"] floating enable, resize set 75 ppt 75 ppt, move position center

        # Floating kitty terminal
        for_window [app_id="floatingkitty"] floating enable, resize set 75 ppt 75 ppt, move position center

        # Firefox file upload dialog
        for_window [class="firefox" title="File Upload"] floating enable, resize set 75 ppt 75 ppt, move position center

        # GEANT4 simulation window
        for_window [class="sim"] floating enable, resize set 75 ppt 75 ppt, move position center

        # ROOT plots 
        for_window [class="ROOT"] floating enable, resize set 75 ppt 75 ppt, move position center

        #GNOME disks 
        for_window [app_id="gnome-disks"] floating enable, resize set 75 ppt 75 ptt, move position center

      '';
    };
  };
}
