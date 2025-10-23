{ config, pkgs, lib, osConfig, ... }:

with lib;

let
  colors = config.colorScheme.palette;
  profile = config.Profile;
  accentColor = if profile == "work" then colors.base09 else colors.base0E;
  # Font selection based on profile
  fontFamily = config.FontChoice;
  radius = toString osConfig.CornerRadius;

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
  programs.wlogout = {
    enable = true;
    package = null;
    layout = [
      {
        label = "logout";
        action = "uwsm stop";
        text = "Logout";
        keybind = "l";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
    ];

    style = ''
      * {
        background-image: none;
        box-shadow: none;
      }

      window {
        background-color: ${hexToRgba colors.base00 "0.75"};
      }

      button {
        color: #${colors.base05};
        background-color: ${hexToRgba colors.base01 "0.8"};
        border-style: solid;
        border-width: 2px;
        border-radius: ${radius}px;
        border-color: ${hexToRgba colors.base04 "0.8"};
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
        font-family: "${fontFamily}";
        font-size: 20px;
        margin: 10px;
        min-width: 150px;
        min-height: 150px;
      }

      button:focus, button:active, button:hover {
        background-color: ${hexToRgba accentColor "0.8"};
        border-color: #${accentColor};
        outline-style: none;
      }

      #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
      }

      #suspend {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      }

      #shutdown {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
      }

      #reboot {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
      }
    '';
  };
}
