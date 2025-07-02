{ config, lib, osConfig, pkgs, ... }:
with lib;
let
  deviceType = osConfig.DeviceType;
  profile = config.Profile;
in {

  imports = [
    ./settings/niri-colors.nix
    ./settings/profile.nix
    ./services/swayidle.nix
    ./services/swaync.nix
    ./services/swaylock.nix
    ./services/wlogout.nix
    ./services/swayosd.nix
    ./launcher/rofi.nix
  ] ++ optionals (deviceType == "laptop") [ ./settings/laptop.nix ]
    ++ optionals (deviceType == "desktop") [ ./settings/desktop.nix ];

  config = {

    programs.niri = {
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
          ];
          default-column-width = { proportion = 0.5; };
          always-center-single-column = true;
        };

        window-rules = [{
          clip-to-geometry = true;

          geometry-corner-radius = {
            top-left = 10.0;
            top-right = 10.0;
            bottom-right = 10.0;
            bottom-left = 10.0;
          };
        }];

        binds = with config.lib.niri.actions; {
          # Basic window management
          "Mod+f".action = spawn "firefox";
          "Mod+Shift+p".action = spawn "firefox" "--private-window";
          "Mod+n".action =
            spawn "firefox" "https://nix-community.github.io/nixvim/25.05/";
          "Mod+p".action = spawn "firefox" "--new-window" "-url"
            "https://search.nixos.org/packages" "-new-tab" "-url"
            "https://search.nixos.org/options?" "-new-tab" "-url"
            "https://home-manager-options.extranix.com/";
          "Alt+l".action.spawn = "swaylock";

          # Basic window management
          "Mod+Return".action.spawn = "kitty";
          "Mod+Shift+q".action = close-window;
          "Mod+d".action.spawn = [ "rofi" "-show" "drun" "-matching" "fuzzy" ];
          "Mod+m".action.spawn = [
            "${pkgs.wlogout}/bin/wlogout"
            "-p"
            "layer-shell"
            "--buttons-per-row"
            "2"
          ];
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
          "Mod+1".action = focus-workspace-up;
          "Mod+2".action = focus-workspace-down;
          "Mod+3".action = focus-monitor-next;
          "Mod+4".action = focus-monitor-previous;

          "Mod+Shift+1".action = move-window-to-workspace-up;
          "Mod+Shift+2".action = move-window-to-workspace-down;
          "Mod+Shift+3".action = move-window-to-monitor-next;
          "Mod+Shift+4".action = move-window-to-monitor-previous;

          # Layout management
          "Mod+Shift+f".action = fullscreen-window;
          "Mod+r".action = switch-preset-column-width;
          "Mod+Comma".action = consume-or-expel-window-left;
          "Mod+Period".action = consume-or-expel-window-right;
          # System controls
          "Mod+Shift+n".action.spawn = [ "swaync-client" "-t" ];
          "Mod+Shift+e".action.spawn = [ "swaync-client" "--close-all" ];

          # Screenshots
          "Alt+Ctrl+3".action.spawn = [ "grimshot" "copy" "output" ];
          "Alt+Ctrl+4".action.spawn = [ "grimshot" "copy" "area" ];

          # Audio controls
          "XF86AudioRaiseVolume".action.spawn =
            [ "swayosd-client" "--output-volume" "raise" ];
          "XF86AudioLowerVolume".action.spawn =
            [ "swayosd-client" "--output-volume" "lower" ];
          "XF86AudioMute".action.spawn =
            [ "swayosd-client" "--output-volume" "mute-toggle" ];
        };
        hotkey-overlay = { skip-at-startup = true; };
        # Spawn programs on startup
        spawn-at-startup = [
          { command = [ "udiskie" "--tray" ]; }
          { command = [ "waybar" ]; }
          { command = [ "xwayland-satellite" ]; }
        ];
        # Animations (optional - Niri has nice animations)
        animations = {
          enable = true;
          slowdown = 1.0;
        };
      };
    };
  };
}
