{ config, pkgs, lib, deviceType, ... }:

with lib;

let
  colors = config.colorScheme.palette;
  profile = config.Profile;
  accentColor = removePrefix "#" colors.base0E;
  fontFamily = if profile == "work" then
    "FiraCode Nerd Font"
  else
    "JetBrains Mono Nerd Font";

  # Helper functions (same as your other files)
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

  hexPairToInt = hex:
    let
      d1 = hexDigitToInt (builtins.substring 0 1 hex);
      d2 = hexDigitToInt (builtins.substring 1 1 hex);
    in d1 * 16 + d2;

  hexToRgba = hex: alpha:
    let
      r = toString (hexPairToInt (builtins.substring 0 2 hex));
      g = toString (hexPairToInt (builtins.substring 2 2 hex));
      b = toString (hexPairToInt (builtins.substring 4 2 hex));
    in "rgba(${r}, ${g}, ${b}, ${alpha})";

  # Custom SwayOSD styling that matches your theme
  swayosdStyle = pkgs.writeText "swayosd-style.css" ''
    window {
      background-color: ${hexToRgba colors.base00 "0.95"};
      border-radius: 10px;
      border: 2px solid #${accentColor};
    }

    #container {
      margin: 20px;
      padding: 16px;
    }

    image {
      color: #${accentColor};
      margin-right: 12px;
    }

    progressbar {
      background-color: ${hexToRgba colors.base02 "0.8"};
      border-radius: 10px;
      min-height: 8px;
      min-width: 200px;
    }

    progressbar progress {
      background-color: #${accentColor};
      border-radius: 10px;
      min-height: 8px;
    }

    label {
      color: #${colors.base05};
      font-family: "${fontFamily}";
      font-size: 16px;
      font-weight: bold;
      margin-left: 8px;
    }

    /* Specific styling for different OSD types */
    .osd-volume {
      background-color: ${hexToRgba colors.base00 "0.95"};
      border: 2px solid #${accentColor};
      border-radius: 10px;
    }

    .osd-brightness {
      background-color: ${hexToRgba colors.base00 "0.95"};
      border: 2px solid #${accentColor};
      border-radius: 10px;
    }
  '';

in {
  services.swayosd = {
    enable = true;
    package = pkgs.swayosd;
    stylePath = swayosdStyle;
    topMargin = 0.85;
  };
}
