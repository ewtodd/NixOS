{ config, pkgs, lib, ... }:

let
  colors = config.colorScheme.palette;
  profile = config.Profile;
  accentColor = if profile == "work" then colors.base09 else colors.base0E;
  # Font selection based on profile
  fontFamily = if profile == "work" then
    "FiraCode Nerd Font"
  else
    "JetBrains Mono Nerd Font";

  # Helper to convert single hex digit to decimal (handles both upper and lowercase)
  hexDigitToInt = d:
    if d == "0" then
      0
    else if d == "1" then
      1
    else if d == "2" then
      2
    else if d == "3" then
      3
    else if d == "4" then
      4
    else if d == "5" then
      5
    else if d == "6" then
      6
    else if d == "7" then
      7
    else if d == "8" then
      8
    else if d == "9" then
      9
    else if d == "a" || d == "A" then
      10
    else if d == "b" || d == "B" then
      11
    else if d == "c" || d == "C" then
      12
    else if d == "d" || d == "D" then
      13
    else if d == "e" || d == "E" then
      14
    else if d == "f" || d == "F" then
      15
    else
      throw "Invalid hex digit: ${d}";

  # Convert two hex digits to decimal
  hexPairToInt = hex:
    let
      d1 = hexDigitToInt (builtins.substring 0 1 hex);
      d2 = hexDigitToInt (builtins.substring 1 1 hex);
    in d1 * 16 + d2;

  # Helper to convert hex to rgba
  hexToRgba = hex: alpha:
    let
      r = toString (hexPairToInt (builtins.substring 0 2 hex));
      g = toString (hexPairToInt (builtins.substring 2 2 hex));
      b = toString (hexPairToInt (builtins.substring 4 2 hex));
    in "rgba(${r}, ${g}, ${b}, ${alpha})";

in {
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "application";
      control-center-margin-top = 0;
      control-center-margin-bottom = 0;
      control-center-margin-right = 0;
      control-center-margin-left = 0;
      notification-2fa-command = true;
      notification-inline-replies = false;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      fit-to-screen = true;
      control-center-width = 600;
      notification-window-width = 500;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = true;
      hide-on-action = true;
      script-fail-notify = true;
      widgets = [ "title" "dnd" "notifications" ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd = { text = "Do Not Disturb"; };
      };
    };

    style = ''
      .control-center {
        background-color: ${hexToRgba colors.base00 "0.75"};
        border: 1px solid ${hexToRgba colors.base05 "0.2"};
        border-radius: 12px;
        margin: 18px;
        padding: 12px;
      }

      .control-center-list {
        background-color: transparent;
      }

      .notification {
        background-color: ${hexToRgba colors.base01 "0.75"};
        border: 1px solid ${hexToRgba colors.base05 "0.1"};
        border-radius: 8px;
        margin: 6px 0;
        padding: 12px;
      }

      .notification-content {
        background-color: transparent;
        padding: 6px;
        border-radius: 8px;
      }

      .summary {
        font-size: 14px;
        font-weight: bold;
        color: #${colors.base05};
        background-color: transparent;
      }

      .time {
        font-size: 12px;
        color: #${colors.base04};
        margin-right: 18px;
        background-color: transparent;
      }

      .body {
        font-size: 13px;
        color: #${colors.base05};
        background-color: transparent;
      }

      .widget-title {
        color: #${colors.base05};
        background-color: ${hexToRgba colors.base01 "0.9"};
        padding: 8px 12px;
        margin: 6px 0;
        border-radius: 8px;
        border: 1px solid ${hexToRgba colors.base05 "0.1"};
      }

      .widget-title > button {
        font-size: 12px;
        color: #${colors.base08};
        text-shadow: none;
        background-color: transparent;
        border: 1px solid #${colors.base08};
        border-radius: 4px;
        padding: 4px 8px;
      }

      .widget-title > button:hover {
        background-color: ${hexToRgba colors.base08 "0.15"};
      }

      .widget-dnd {
        background-color: ${hexToRgba colors.base01 "0.9"};
        border: 1px solid ${hexToRgba colors.base05 "0.1"};
        border-radius: 8px;
        margin: 6px 0;
        padding: 8px;
        color: #${colors.base05};
      }

      .widget-dnd > switch {
        background-color: #${colors.base02};
        border-radius: 8px;
      }

      .widget-dnd > switch:checked {
        background-color: ${hexToRgba colors.base08 "0.8"};
      }

    '';
  };
}
