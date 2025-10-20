{ config, lib, osConfig, pkgs, ... }:
with lib;
let
  deviceType = osConfig.DeviceType;
  wallpaperPath = config.WallpaperPath;
  open-nix-docs = pkgs.writeShellScript "open-nix-docs" ''
    ${pkgs.firefox-wayland}/bin/firefox --new-window \
      -url https://search.nixos.org/packages \
      -new-tab -url https://search.nixos.org/options? \
      -new-tab -url https://home-manager-options.extranix.com/ &
  '';
  toggle-overview-with-waybar =
    pkgs.writeShellScript "toggle-overview-with-waybar" ''
      # Check current overview state
      OVERVIEW_STATE=$(${pkgs.niri}/bin/niri msg overview-state)

      if [[ "$OVERVIEW_STATE" == *"open"* ]]; then
        ${pkgs.waybar}/bin/waybar &
        sleep 0.2
        ${pkgs.niri}/bin/niri msg action close-overview 
      else
        ${pkgs.procps}/bin/pkill waybar
        ${pkgs.niri}/bin/niri msg action open-overview 
      fi
    '';
in {

  imports = [
    ./non-niri.nix
    ./settings/profile.nix
    ./settings/niri-colors.nix
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
      package = osConfig.programs.niri.package;
      settings = {
        prefer-no-csd = true;
        input = {

          focus-follows-mouse.enable = true;
          touchpad = mkIf (deviceType == "laptop") {
            tap = true;
            natural-scroll = true;
            tap-button-map = "left-right-middle";
          };

          mouse = { natural-scroll = true; };
        };

        gestures = { hot-corners.enable = false; };

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

        layer-rules = [{
          matches = [{ namespace = "swaync-notification-window"; }];
          block-out-from = "screen-capture";
        }];

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
            default-column-width.proportion = 0.6;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ title = "Volume Control"; }];
            open-floating = true;
            default-column-width.proportion = 0.6;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ app-id = "floatingkitty"; }];
            open-floating = true;
            default-column-width.proportion = 0.6;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{
              app-id = "firefox";
              title = "File Upload";
            }];
            open-floating = true;
            default-column-width.proportion = 0.6;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ title = "sim"; }];
            open-floating = true;
            default-column-width.proportion = 0.6;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ title = "ROOT"; }];
            open-floating = true;
            default-column-width.proportion = 0.6;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ app-id = "gnome-disks"; }];
            open-floating = true;
            default-column-width.proportion = 0.6;
            default-window-height.proportion = 0.6;
          }
        ];

        binds = with config.lib.niri.actions; {
          "Mod+f".action.spawn = "${pkgs.firefox-wayland}/bin/firefox";
          "Mod+Shift+p".action.spawn =
            [ "${pkgs.firefox-wayland}/bin/firefox" "--private-window" ];
          "Mod+n".action.spawn = [
            "${pkgs.firefox-wayland}/bin/firefox"
            "-new-window"
            "https://nix-community.github.io/nixvim/25.05/"
          ];
          "Mod+p".action = spawn "${open-nix-docs}";
          "Mod+Shift+g".action = spawn [
            "${pkgs.firefox-wayland}/bin/firefox"
            "--private-window"
            "https://looptube.io/?videoId=eaPT0dQgS9E&start=0&end=4111&rate=1"
          ];

          "Mod+Return".action.spawn = "${pkgs.kitty}/bin/kitty";
          "Mod+Shift+Return".action.spawn =
            [ "${pkgs.kitty}/bin/kitty" "--class" "'floatingkitty'" ];
          "Mod+Shift+q".action = close-window;
          "Mod+d".action.spawn = [
            "${pkgs.rofi-wayland}/bin/rofi"
            "-show"
            "drun"
            "-matching"
            "fuzzy"
          ];
          "Mod+Shift+d".action.spawn = [
            "${pkgs.rofi-wayland}/bin/rofi"
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

          "Mod+Tab".action.spawn = "${toggle-overview-with-waybar}";

          # Workspaces
          "Mod+a".action = focus-workspace-up;
          "Mod+s".action = focus-workspace-down;
          "Mod+c".action = focus-monitor-next;
          "Mod+v".action = focus-monitor-previous;

          "Mod+Shift+a".action = move-window-to-workspace-up;
          "Mod+Shift+s".action = move-window-to-workspace-down;
          "Mod+Shift+c".action = move-window-to-monitor-next;
          "Mod+Shift+v".action = move-window-to-monitor-previous;

          # Layout management
          "Mod+Shift+f".action = fullscreen-window;
          "Mod+r".action = switch-preset-column-width;
          "Mod+Comma".action = consume-or-expel-window-left;
          "Mod+Period".action = consume-or-expel-window-right;
          "Mod+Space".action = toggle-window-floating;
          "Mod+Shift+Space".action = center-window;

          # System controls
          "Mod+Shift+n".action.spawn =
            [ "${pkgs.swaynotificationcenter}/bin/swaync-client" "-t" ];
          "Mod+Shift+e".action.spawn = [
            "${pkgs.swaynotificationcenter}/bin/swaync-client"
            "--close-all"
          ];

          # Screenshots
          "Alt+Ctrl+3".action.spawn =
            [ "${pkgs.sway-contrib.grimshot}/bin/grimshot" "copy" "output" ];
          "Alt+Ctrl+4".action.spawn =
            [ "${pkgs.sway-contrib.grimshot}/bin/grimshot" "copy" "area" ];

          # Audio controls
          "XF86AudioRaiseVolume".action.spawn = [ "volumectl" "-u" "up" ];
          "XF86AudioLowerVolume".action.spawn = [ "volumectl" "-u" "down" ];
          "XF86AudioMute".action.spawn = [ "volumectl" "toggle-mute" ];

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
          { command = [ "wayland-pipewire-idle-inhibit" ]; }
        ];
        animations = {
          enable = true;
          slowdown = 1.0;
        };
      };
    };
  };
}
