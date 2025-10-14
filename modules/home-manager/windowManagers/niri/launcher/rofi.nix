{ config, pkgs, osConfig, ... }:

let
  colors = config.colorScheme.palette;
  inherit (config.lib.formats.rasi) mkLiteral;
  windowManager = osConfig.WindowManager;
  opacity = if (windowManager == "sway") then "0.75" else "0.875";
  hexToRgba = hex: alpha:
    let
      r = toString (hexPairToInt (builtins.substring 0 2 hex));
      g = toString (hexPairToInt (builtins.substring 2 2 hex));
      b = toString (hexPairToInt (builtins.substring 4 2 hex));
    in "rgba(${r}, ${g}, ${b}, ${alpha})";
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

in {

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.kitty}/bin/kitty";
    modes = [ "drun" "window" "combi" "ssh" "filebrowser" ];
    cycle = true;
    extraConfig = {
      show-icons = true;
      display-drun = " ";
      drun-display-format = "{name}";
    };
  };

  programs.rofi.theme = {
    "*" = {
      background-color = mkLiteral "#${colors.base00}";
      border-color = mkLiteral "#${colors.base00}";
      text-color = mkLiteral "#${colors.base05}";
      selection-background-color = mkLiteral "#${colors.base02}";
      selection-text-color = mkLiteral "#${colors.base05}";
      separatorcolor = mkLiteral "#${colors.base00}";
      urgent-background-color = mkLiteral "#${colors.base08}";
      urgent-text-color = mkLiteral "#${colors.base00}";
      active-background-color = mkLiteral "#${colors.base0D}";
      active-text-color = mkLiteral "#${colors.base00}";
    };

    window = {
      background-color = "${hexToRgba colors.base00 "${opacity}"}";
      text-color = mkLiteral "#${colors.base05}";
      border = mkLiteral "0px";
      border-color = mkLiteral "#${colors.base03}";
      border-radius = mkLiteral "0px";
      width = mkLiteral "100%";
      height = mkLiteral "100%";
      location = mkLiteral "center";
      anchor = mkLiteral "center";
      fullscreen = true;
      x-offset = mkLiteral "0px";
      y-offset = mkLiteral "0px";
      cursor = "default";
    };

    mainbox = {
      background-color = mkLiteral "transparent";
      border = mkLiteral "0px";
      border-radius = mkLiteral "0px";
      border-color = mkLiteral "#${colors.base03}";
      children = mkLiteral ''[ "inputbar", "listview" ]'';
      spacing = mkLiteral "100px";
      padding = mkLiteral "100px 225px";
    };

    inputbar = {
      children = mkLiteral ''[ "prompt", "entry" ]'';
      background-color = mkLiteral "#${colors.base00}1a";
      text-color = mkLiteral "#${colors.base05}";
      expand = false;
      border = mkLiteral "2px solid";
      border-radius = mkLiteral "10px";
      border-color = mkLiteral "#${colors.base03}";
      margin = mkLiteral "0% 25%";
      padding = mkLiteral "18px";
      spacing = mkLiteral "10px";
    };

    prompt = {
      enabled = true;
      background-color = mkLiteral "transparent";
      text-color = mkLiteral "#${colors.base09}";
    };

    entry = {
      background-color = mkLiteral "transparent";
      text-color = mkLiteral "#${colors.base05}";
      cursor = mkLiteral "text";
      placeholder = "Search";
      placeholder-color = mkLiteral "#${colors.base03}";
    };

    listview = {
      background-color = mkLiteral "transparent";
      columns = 8;
      lines = 4;
      spacing = mkLiteral "0px";
      cycle = true;
      dynamic = true;
      layout = mkLiteral "vertical";
      reverse = false;
      scrollbar = false;
      fixed-height = true;
      fixed-columns = true;
      border = mkLiteral "0px";
      border-radius = mkLiteral "0px";
      border-color = mkLiteral "#${colors.base03}";
      cursor = "default";
    };

    element = {
      background-color = mkLiteral "transparent";
      text-color = mkLiteral "#${colors.base05}";
      orientation = mkLiteral "vertical";
      border-radius = mkLiteral "15px";
      padding = mkLiteral "35px 10px";
      spacing = mkLiteral "15px";
      cursor = mkLiteral "pointer";
    };

    "element normal.normal" = {
      background-color = mkLiteral "transparent";
      text-color = mkLiteral "#${colors.base05}";
    };

    "element normal.urgent" = {
      background-color = mkLiteral "#${colors.base08}";
      text-color = mkLiteral "#${colors.base00}";
    };

    "element normal.active" = {
      background-color = mkLiteral "#${colors.base0D}";
      text-color = mkLiteral "#${colors.base00}";
    };

    "element selected.normal" = {
      background-color = mkLiteral "#${colors.base02}";
      text-color = mkLiteral "#${colors.base05}";
      border = mkLiteral "2px solid";
      border-color = mkLiteral "#${colors.base03}";
    };

    "element selected.urgent" = {
      background-color = mkLiteral "#${colors.base08}";
      text-color = mkLiteral "#${colors.base00}";
    };

    "element selected.active" = {
      background-color = mkLiteral "#${colors.base0D}";
      text-color = mkLiteral "#${colors.base00}";
    };

    element-icon = {
      background-color = mkLiteral "transparent";
      text-color = mkLiteral "inherit";
      size = mkLiteral "72px";
      cursor = mkLiteral "inherit";
    };

    element-text = {
      background-color = mkLiteral "transparent";
      text-color = mkLiteral "inherit";
      expand = true;
      horizontal-align = mkLiteral "0.5";
      vertical-align = mkLiteral "0.5";
      margin = mkLiteral "0px 2px 0px 2px";
      cursor = mkLiteral "inherit";
    };

    scrollbar = {
      width = mkLiteral "4px";
      border = mkLiteral "0px";
      handle-color = mkLiteral "#${colors.base03}";
      handle-width = mkLiteral "8px";
      padding = mkLiteral "0px";
    };

    sidebar = {
      border = mkLiteral "0px";
      border-color = mkLiteral "#${colors.base03}";
      border-radius = mkLiteral "0px";
    };

    button = {
      cursor = mkLiteral "pointer";
      background-color = mkLiteral "transparent";
      text-color = mkLiteral "#${colors.base05}";
    };

    "button selected" = {
      background-color = mkLiteral "#${colors.base02}";
      text-color = mkLiteral "#${colors.base05}";
    };

    message = {
      border = mkLiteral "0px";
      border-color = mkLiteral "#${colors.base03}";
      padding = mkLiteral "100px";
    };

    textbox = {
      text-color = mkLiteral "#${colors.base05}";
      background-color = mkLiteral "transparent";
    };
  };

}
