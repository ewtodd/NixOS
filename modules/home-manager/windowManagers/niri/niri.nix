{ config, pkgs, lib, osConfig, ... }:

with lib;
let deviceType = osConfig.DeviceType;
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
        environment.DISPLAY = ":0";
        prefer-no-csd = true;
        input = {

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
          center-focused-column = "never";
          preset-column-widths = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
          ];
          default-column-width = { proportion = 0.5; };

        };
       
        # Key bindings - converted from your Sway config
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

          # Basic window management
          "Mod+Return".action.spawn = "kitty";
          "Mod+Shift+q".action.close-window = { };
          "Mod+d".action.spawn = [ "rofi" "-show" "drun" "-matching" "fuzzy" ];

          # Focus management (vim-style)
          "Mod+h".action.focus-column-left = { };
          "Mod+j".action.focus-window-down = { };
          "Mod+k".action.focus-window-up = { };
          "Mod+l".action.focus-column-right = { };

          # Move windows
          "Mod+Shift+h".action.move-column-left = { };
          "Mod+Shift+j".action.move-window-down = { };
          "Mod+Shift+k".action.move-window-up = { };
          "Mod+Shift+l".action.move-column-right = { };

          # Workspaces
          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;
          "Mod+6".action.focus-workspace = 6;
          "Mod+7".action.focus-workspace = 7;
          "Mod+8".action.focus-workspace = 8;
          "Mod+9".action.focus-workspace = 9;
          "Mod+0".action.focus-workspace = 10;

          # Move to workspaces - CORRECTED SYNTAX
          "Mod+Shift+1".action.move-column-to-workspace = 1;
          "Mod+Shift+2".action.move-column-to-workspace = 2;
          "Mod+Shift+3".action.move-column-to-workspace = 3;
          "Mod+Shift+4".action.move-column-to-workspace = 4;
          "Mod+Shift+5".action.move-column-to-workspace = 5;
          "Mod+Shift+6".action.move-column-to-workspace = 6;
          "Mod+Shift+7".action.move-column-to-workspace = 7;
          "Mod+Shift+8".action.move-column-to-workspace = 8;
          "Mod+Shift+9".action.move-column-to-workspace = 9;
          "Mod+Shift+0".action.move-column-to-workspace = 10;

          # Layout management
          "Mod+Shift+f".action.fullscreen-window = { };
          "Mod+r".action.switch-preset-column-width = { };

          # System controls
          "Mod+Shift+c".action.spawn =
            [ "niri" "msg" "action" "reload-config" ];
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
