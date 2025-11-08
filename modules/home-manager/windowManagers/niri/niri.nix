{ config, lib, osConfig, pkgs, ... }:
with lib;
let
  colors = config.colorScheme.palette;
  deviceType = osConfig.DeviceType;
  radius = 1.0 * osConfig.CornerRadius;
  wallpaperPath = config.WallpaperPath;
  open-nix-docs = pkgs.writeShellScript "open-nix-docs" ''
    ${pkgs.firefox-wayland}/bin/firefox --new-window \
      -url https://search.nixos.org/packages \
      -new-tab -url https://search.nixos.org/options? \
      -new-tab -url https://home-manager-options.extranix.com/ &
  '';
  notificationColor =
    if (colors.base08 != colors.base0E) then colors.base08 else "F84F31";
in {

  imports = [
    ./non-niri.nix
    ./settings/niri-colors.nix
    ./services/swayidle.nix
    ./services/swaync.nix
    ./services/swaylock.nix
    ./services/wlogout.nix
    ./services/avizo.nix
    ./services/tile-to-n.nix
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

        layout = {
          gaps = 12;
          preset-column-widths = [
            { proportion = 0.5; }
            { proportion = 0.75; }
            { proportion = 1.0; }
          ];
          preset-window-heights = [
            { proportion = 0.5; }
            { proportion = 0.75; }
            { proportion = 1.0; }
          ];
          always-center-single-column = true;
          center-focused-column = "on-overflow";
        };

        layer-rules = [{
          matches = [{ namespace = "swaync-notification-window"; }];
          block-out-from = "screen-capture";
        }];

        window-rules = [
          {
            clip-to-geometry = true;

            geometry-corner-radius = {
              top-left = radius;
              top-right = radius;
              bottom-right = radius;
              bottom-left = radius;
            };
          }
          {
            matches = [{ is-window-cast-target = true; }];
            border = {
              enable = true;
              width = 3;
              active.color = "#${notificationColor}";
              inactive.color = "#${notificationColor}";
            };
            focus-ring.enable = false;
          }

          {
            matches = [{
              app-id = "thunderbird";
              title = "^Write:";
            }];
            open-floating = true;
            default-column-width.proportion = 0.4;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ title = "Volume Control"; }];
            open-floating = true;
            default-column-width.proportion = 0.4;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ app-id = "floatingkitty"; }];
            open-floating = true;
            default-column-width.proportion = 0.4;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ app-id = ".blueman-manager-wrapped"; }];
            open-floating = true;
            default-column-width.proportion = 0.4;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ app-id = "udiskie"; }];
            open-floating = true;
            default-column-width.proportion = 0.4;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ app-id = "LISE++"; }];
            open-floating = true;
            default-column-width = { };
            default-window-height = { };
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
            default-column-width.proportion = 0.4;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ title = "ROOT"; }];
            open-floating = true;
            default-column-width.proportion = 0.4;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ app-id = "gnome-disks"; }];
            open-floating = true;
            default-column-width.proportion = 0.4;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{ app-id = "com.obsproject.Studio"; }];
            default-column-width.proportion = 1.0;
          }
          {
            matches = [{
              app-id = "com.obsproject.Studio";
              title = "^Create/Select Source";
            }];
            open-floating = true;
            default-column-width.proportion = 0.4;
            default-window-height.proportion = 0.6;
          }
          {
            matches = [{
              app-id = "com.obsproject.Studio";
              title = "^Properties for 'Screen Capture (PipeWire)'";
            }];
            open-floating = true;
            default-column-width.proportion = 0.4;
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
            "combi"
            "-modes"
            "combi"
            "-combi-modes"
            "window,drun"
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
          "Mod+h".action = focus-column-or-monitor-left;
          "Mod+j".action = focus-window-or-workspace-down;
          "Mod+k".action = focus-window-or-workspace-up;
          "Mod+l".action = focus-column-or-monitor-right;
          "Mod+t".action = switch-focus-between-floating-and-tiling;

          # Move windows
          "Mod+Shift+h".action = move-column-left-or-to-monitor-left;
          "Mod+Shift+j".action = move-window-down-or-to-workspace-down;
          "Mod+Shift+k".action = move-window-up-or-to-workspace-up;
          "Mod+Shift+l".action = move-column-right-or-to-monitor-right;

          "Mod+Tab".action = toggle-overview;

          # Workspaces
          "Mod+a".action = focus-workspace-up;
          "Mod+s".action = focus-workspace-down;
          "Mod+1".action = focus-monitor-next;

          "Mod+Shift+a".action = move-window-to-workspace-up;
          "Mod+Shift+s".action = move-window-to-workspace-down;
          "Mod+Shift+1".action = move-window-to-monitor-next;

          # Layout management
          "Mod+Shift+f".action = fullscreen-window;
          "Mod+Ctrl+f".action = toggle-windowed-fullscreen;
          "Mod+r".action = switch-preset-column-width;
          "Mod+Shift+r".action = switch-preset-window-height;
          "Mod+w".action = center-column;
          "Mod+Shift+w".action = center-visible-columns;
          "Mod+c".action = consume-or-expel-window-left;
          "Mod+v".action = consume-or-expel-window-right;
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
            [ "niri" "msg" "action" "screenshot-screen" ];
          "Alt+Ctrl+4".action.spawn = [ "niri" "msg" "action" "screenshot" ];

          # Audio controls
          "XF86AudioRaiseVolume".action.spawn = [ "volumectl" "-d" "-p" "up" ];
          "XF86AudioLowerVolume".action.spawn =
            [ "volumectl" "-d" "-p" "down" ];
          "XF86AudioMute".action.spawn =
            [ "volumectl" "-d" "-p" "toggle-mute" ];

          "XF86MonBrightnessUp".action.spawn = [ "lightctl" "up" ];
          "XF86MonBrightnessDown".action.spawn = [ "lightctl" "down" ];
          "F8".action.spawn = [ "lightctl" "up" ];
          "F7".action.spawn = [ "lightctl" "down" ];
        };

        hotkey-overlay = { skip-at-startup = true; };
        spawn-at-startup = [
          { command = [ "waybar" ]; }
          { command = [ "swaybg" "-i" "${wallpaperPath}" ]; }
          {
            command = [ "sh" "-c" "sleep 2 && wayland-pipewire-idle-inhibit" ];
          }
        ];
        animations = {
          enable = true;
          slowdown = 1.0;
        };
      };
    };
  };
}
