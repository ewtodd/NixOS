{ config, lib, osConfig, ... }:
let
  colors = config.colorScheme.palette;
  windowManager = osConfig.WindowManager;
  opacity = if (windowManager == "sway") then "0.75" else "1";
  radius = osConfig.CornerRadius;
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
  systemd.user.services.swaync = {
    Unit = {
      After = lib.mkForce [ "graphical-session-pre.target" ];
      Before = [ "graphical-session.target" ];
    };
    Install = { WantedBy = lib.mkForce [ "graphical-session-pre.target" ]; };
  };
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      layer-shell = true;
      layer-shell-cover-screen = true;
      cssPriority = "user";
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
      notification-window-width = 500;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = true;
      hide-on-action = true;
      script-fail-notify = true;
      widgets = [ "title" "dnd" "backlight" "volume" "notifications" ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd = { text = "Do Not Disturb"; };
        volume = {
          label = " ";
          show-per-app = false;
        };
        backlight = { label = " "; };
      };
    };

    style = ''
      * {
        background-color: ${hexToRgba colors.base00 "0"};
      }

      .control-center {
        background-color: ${hexToRgba colors.base00 "${opacity}"};
        border: 0px;
        border-radius: 0px;
        margin: 0px;
        padding: 12px;
      }

      .control-center-list {
        background-color: transparent;
      }

      .notification {
        background-color: ${hexToRgba colors.base00 "1"};
        border: 1px solid ${hexToRgba colors.base05 "0.1"};
        border-radius: ${toString radius}px;
        margin: 6px 0;
        padding: 12px;
      }

      .notification-content {
        background-color: transparent;
        padding: 6px;
        border-radius: ${toString radius}px;
      }

      .widget-title {
        color: #${colors.base05};
        background-color: ${hexToRgba colors.base01 "${opacity}"};
        padding: 8px 12px;
        margin: 6px 0;
        border-radius: ${toString radius}px;
        border: 1px solid ${hexToRgba colors.base05 "0.1"};
      }

      .widget-title > button {
        font-size: 12px;
        color: #${colors.base08};
        text-shadow: none;
        background-color: transparent;
        border: 1px solid #${colors.base08};
        border-radius: ${toString radius}px;
        padding: 4px 8px;
      }

      .widget-title > button:hover {
        background-color: ${hexToRgba colors.base08 "0.15"};
      }

      .widget-dnd {
        background-color: ${hexToRgba colors.base01 "0.9"};
        border: 1px solid ${hexToRgba colors.base05 "0.1"};
        border-radius: ${toString radius}px;
        margin: 6px 0;
        padding: 8px;
        color: #${colors.base05};
      }

      .widget-dnd > switch {
        background-color: #${colors.base02};
        border-radius: ${toString radius}px;
      }

      .widget-dnd > switch:checked {
        background-color: ${hexToRgba colors.base08 "0.8"};
      }

      /* Volume widget styling */
      .widget-volume {
        background-color: ${hexToRgba colors.base01 "${opacity}"};
        border: 1px solid ${hexToRgba colors.base05 "0.1"};
        border-radius: ${toString radius}px;
        margin: 6px 0;
        padding: 12px;
        color: #${colors.base05};
      }

      .widget-volume > label {
        font-size: 14px;
        font-weight: bold;
        margin-bottom: 8px;
      }

      .widget-backlight {
        background-color: ${hexToRgba colors.base01 "${opacity}"};
        border: 1px solid ${hexToRgba colors.base05 "0.1"};
        border-radius: ${toString radius}px;
        margin: 6px 0;
        padding: 12px;
        color: #${colors.base05};
      }

      .widget-backlight > label {
        font-size: 15px;
      }

    '';
  };
}
