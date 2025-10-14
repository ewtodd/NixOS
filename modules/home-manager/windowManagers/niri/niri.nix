{ config, lib, osConfig, pkgs, ... }:
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
  open-nix-docs = pkgs.writeShellScript "open-nix-docs" ''
    ${pkgs.firefox-wayland}/bin/firefox --new-window \
      -url https://search.nixos.org/packages \
      -new-tab -url https://search.nixos.org/options? \
      -new-tab -url https://home-manager-options.extranix.com/ &
  '';
in {

  imports = [
    ./settings/niri-colors.nix
    ./settings/profile.nix
    ./services/swayidle.nix
    ./services/swaync.nix
    ./services/swaylock.nix
    ./services/wlogout.nix
    ./services/avizo.nix
    ./launcher/rofi.nix
  ] ++ optionals (deviceType == "laptop") [ ./settings/laptop.nix ]
    ++ optionals (deviceType == "desktop") [ ./settings/desktop.nix ];

  config = {

    programs.niri = {
      enable = true;
      settings = {
        environment = { DISPLAY = ":0"; };
        prefer-no-csd = true;
        cursor = { size = 18; };
        input = {

          focus-follows-mouse.enable = true;
          touchpad = mkIf (deviceType == "laptop") {
            tap = true;
            natural-scroll = true;
            tap-button-map = "left-right-middle";
          };

          mouse = { natural-scroll = true; };
        };

        # Layout configuration
        layout = {
          gaps = 2;
          preset-column-widths = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
            { proportion = 1.0; }
          ];
          default-column-width = { proportion = 0.66667; };
          always-center-single-column = true;
        };

        window-rules = [
          {
            clip-to-geometry = true;

            geometry-corner-radius = {
              top-left = 10.0;
              top-right = 10.0;
              bottom-right = 10.0;
              bottom-left = 10.0;
            };
          }

          {
            matches = [{
              app-id = "thunderbird";
              title = "^Write:";
            }];
            open-floating = true;
            default-column-width.proportion = 0.75;
            default-window-height.proportion = 0.75;
            center-window = true;
          }
          {
            matches = [{ title = "Volume Control"; }];
            open-floating = true;
            default-column-width.proportion = 0.75;
            default-window-height.proportion = 0.75;
            center-window = true;
          }
          {
            matches = [{ app-id = "floatingkitty"; }];
            open-floating = true;
            default-column-width.proportion = 0.75;
            default-window-height.proportion = 0.75;
            center-window = true;
          }
          {
            matches = [{
              app-id = "firefox";
              title = "File Upload";
            }];
            open-floating = true;
            default-column-width.proportion = 0.75;
            default-window-height.proportion = 0.75;
            center-window = true;
          }
          {
            matches = [{ class = "sim"; }];
            open-floating = true;
            default-column-width.proportion = 0.75;
            default-window-height.proportion = 0.75;
            center-window = true;
          }
          {
            matches = [{ class = "ROOT"; }];
            open-floating = true;
            default-column-width.proportion = 0.75;
            default-window-height.proportion = 0.75;
            center-window = true;
          }
          {
            matches = [{ app-id = "gnome-disks"; }];
            open-floating = true;
            default-column-width.proportion = 0.75;
            default-window-height.proportion = 0.75;
            center-window = true;
          }
        ];

        binds = with config.lib.niri.actions; {
          "Mod+f".action.spawn = "firefox";
          "Mod+Shift+p".action.spawn = [ "firefox" "--private-window" ];
          "Mod+n".action.spawn = [
            "firefox"
            "-new-window"
            "https://nix-community.github.io/nixvim/25.05/"
          ];
          "Mod+p".action = spawn "${open-nix-docs}";
          "Mod+Shift+g".action = spawn [
            "firefox"
            "--private-window"
            "https://looptube.io/?videoId=eaPT0dQgS9E&start=0&end=4111&rate=1"
          ];

          "Mod+Return".action.spawn = "kitty";
          "Mod+Shift+Return".action.spawn =
            [ "kitty" "--class" "'floatingkitty'" ];
          "Mod+Shift+q".action = close-window;
          "Mod+d".action.spawn = [ "rofi" "-show" "drun" "-matching" "fuzzy" ];
          "Mod+Shift+d".action.spawn = [
            "rofi"
            "-show"
            "filebrowser"
            "-matching"
            "fuzzy"
            "-filebrowser-directory"
            "~"
          ];
          "Mod+m".action.spawn = [
            "${pkgs.wlogout}/bin/wlogout"
            "-p"
            "layer-shell"
            "--buttons-per-row"
            "2"
          ];
          "Alt+l".action.spawn = "${pkgs.swaylock-effects}/bin/swaylock";
          # Focus management (vim-style)
          "Mod+h".action = focus-column-left;
          "Mod+j".action = focus-window-down;
          "Mod+k".action = focus-window-up;
          "Mod+l".action = focus-column-right;

          # Move windows
          "Mod+Shift+h".action = move-column-left;
          "Mod+Shift+j".action = move-window-down;
          "Mod+Shift+k".action = move-window-up;
          "Mod+Shift+l".action = move-column-right;

          "Mod+Tab".action = toggle-overview;

          # Workspaces
          "Mod+a".action = focus-workspace-up;
          "Mod+s".action = focus-workspace-down;
          "Mod+1".action = focus-monitor-next;
          "Mod+2".action = focus-monitor-previous;

          "Mod+Shift+a".action = move-window-to-workspace-up;
          "Mod+Shift+s".action = move-window-to-workspace-down;
          "Mod+Shift+1".action = move-window-to-monitor-next;
          "Mod+Shift+2".action = move-window-to-monitor-previous;

          # Layout management
          "Mod+Shift+f".action = fullscreen-window;
          "Mod+r".action = switch-preset-column-width;
          "Mod+Comma".action = consume-or-expel-window-left;
          "Mod+Period".action = consume-or-expel-window-right;
          "Mod+Space".action = toggle-window-floating;
          "Mod+Shift+Space".action = center-window;

          # System controls
          "Mod+Shift+n".action.spawn = [ "swaync-client" "-t" ];
          "Mod+Shift+e".action.spawn = [ "swaync-client" "--close-all" ];

          # Screenshots
          "Alt+Ctrl+3".action.spawn = [ "grimshot" "copy" "output" ];
          "Alt+Ctrl+4".action.spawn = [ "grimshot" "copy" "area" ];

          # Audio controls
          "XF86AudioRaiseVolume".action.spawn = [ "volumectl" "-u" "up" ];
          "XF86AudioLowerVolume".action.spawn = [ "volumectl" "-u" "down" ];
          "XF86AudioMute".action.spawn = [ "swayosd-client" "toggle-mute" ];

          "XF86MonBrightnessUp".action.spawn = [ "lightctl" "up" ];
          "XF86MonBrightnessDown".action.spawn = [ "lightctl" "down" ];
          "F8".action.spawn = [ "lightctl" "up" ];
          "F7".action.spawn = [ "lightctl" "down" ];
        };

        hotkey-overlay = { skip-at-startup = true; };
        # Spawn programs on startup
        spawn-at-startup = [
          { command = [ "waybar" ]; }
          { command = [ "swaybg" "-i" "${wallpaperPath}" ]; }
        ];
        animations = {
          enable = true;
          slowdown = 1.0;
        };
      };
    };
  };
}
