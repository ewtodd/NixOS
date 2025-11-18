{ lib, config, osConfig, ... }:
let
  colors = config.colorScheme.palette;
  radius = toString osConfig.CornerRadius;
  fontFamily = config.FontChoice;
  accentColor = colors.base0E;
  windowManager = osConfig.WindowManager;
  opacity = if (windowManager == "sway") then "0.75" else "0.925";
  deviceType = osConfig.DeviceType;
  left-notification-padding =
    if (fontFamily == "JetBrains Mono Nerd Font") then "5px" else "8px";
  right-info-padding =
    if (fontFamily == "JetBrains Mono Nerd Font") then "7px" else "3px";
  right-notification-padding =
    if (fontFamily == "JetBrains Mono Nerd Font") then "8px" else "7px";
  right-network-padding =
    if (fontFamily == "JetBrains Mono Nerd Font") then "10px" else "9px";
  left-network-padding =
    if (fontFamily == "JetBrains Mono Nerd Font") then "8px" else "10px";
  right-notification-dnd-padding =
    if (fontFamily == "JetBrains Mono Nerd Font") then "11px" else "7px";
  notificationColor =
    if (colors.base08 != colors.base0E) then colors.base08 else "F84F31";
  # Helper to convert hex to rgba
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
  programs.waybar.style = ''
    * {
    	border: none;
    	border-radius: 0;
    	min-height: 0;
    	font-family: "${fontFamily}";
    	font-size: 1.0rem;
    }

    window#waybar {
    	background-color: ${hexToRgba colors.base00 "${opacity}"};
    }

    #workspaces button:first-child {
        margin-left: 3px;
    	border-radius: ${radius}px 0 0 ${radius}px;
    	border-right: 1px solid #${colors.base03};
    }

    #workspaces {
    	background: transparent;
    	margin: 5px 0;
    	font-size: 1.0rem;
    }

    #workspaces button:first-child:last-child {
    	border-radius: ${radius}px;
    	margin-left: 3px;
    	border-right: none;
    }

    #workspaces button:last-child {
        border: none;
        border-radius: 0 ${radius}px ${radius}px 0; 
    }

    #workspaces button {
    	all: initial;
    	min-width: 24px;
    	padding: 6px 10px;
    	margin: 0;
    	border-radius: 0;
    	background-color: #${colors.base00};
    	color: #${accentColor};
    	transition: background 0.2s, color 0.2s;
    	border-left: none;
    }

    #workspaces button:not(:last-child) {
    	border-right: 1px solid #${colors.base03};
    }

    #workspaces button.focused {
    	background-color: #${colors.base00};
    	color: #${accentColor};
    	border: 2px solid #${colors.base04};
    }

    #workspaces button.focused:first-child:last-child {
    	background-color: #${colors.base00};
    	color: #${accentColor};
    	border: 2px solid #${colors.base04};
    }

    #workspaces button:hover {
    	color: #${colors.base00};
    	background-color: #${accentColor};
    }

    #workspaces button.urgent {
    	background-color: #${colors.base08};
    	color: #${colors.base00};
    }

    #window {
    	opacity: 0;
    	min-width: 0;
    	padding: 0;
    	margin: 0;
    }

    #mode {
    	all: initial;
    	min-width: 0;
    	box-shadow: none;
    	padding: 6px 10px;
    	margin: 5px 3px;
    	border-radius: ${radius}px;
    	background-color: #${colors.base00};
    	color: #${colors.base0C};
    	border: none;
    }

    #custom-cpu {
    	background-color: #${colors.base00};
    	color: #${accentColor};
    	padding: 6px 10px;
    	border-radius: ${radius}px 0 0 ${radius}px;
    	margin: 5px 0 5px 3px;
    	border-right: 1px solid #${colors.base03};
    	border-left: none;
    }

    #memory {
    	background-color: #${colors.base00};
    	color: #${accentColor};
    	padding: 6px 10px;
    	border-radius: 0;
    	border-right: 1px solid #${colors.base03};
        border-left: none;
        border-radius: ${
          if deviceType != "desktop" then "0 ${radius} ${radius} 0" else "0"
        };
        margin: ${if deviceType != "desktop" then "5px 3px 5px 0" else "5px 0"};
        border-right: ${
          if deviceType != "desktop" then
            "none"
          else
            "1px solid #${colors.base03}"
        };
    }

    #custom-gpu {
    	background-color: #${colors.base00};
    	color: #${accentColor};
    	padding: 6px 10px;
    	border-radius: 0;
    	margin: 5px 0;
    	border-right: 1px solid #${colors.base03};
    	border-left: none;
    }

    #custom-gpumemory {
    	background-color: #${colors.base00};
    	color: #${accentColor};
    	padding: 6px 10px;
    	border-right: 1px solid #${colors.base03};
    	border-radius: 0 ${radius}px ${radius}px 0;
    	margin: 5px 3px 5px 0;
    	border-right: none;
    	border-left: none;
    }


    #custom-notification.notification,
    #custom-notification.dnd-notification,
    #custom-notification.inhibited-notification,
    #custom-notification.dnd-inhibited-notification {
    	color: #${notificationColor};

    }

    #custom-notification.dnd-none,
    #custom-notification.inhibited-none,
    #custom-notification.dnd-inhibited-none,
    #custom-notification.dnd-notification,
    #custom-notification.inhibited-notification,
    #custom-notification.dnd-inhibited-notification {
    	padding-right: ${right-notification-dnd-padding};
    }

    #custom-info {
    	background-color: ${hexToRgba colors.base00 "0"};
    	color: #${accentColor};
    	padding-top: 0;
    	padding-bottom: 0;
        padding-left: 0;
    	padding-right: ${right-info-padding};
    	margin: 5px 0 5px 3px;
        min-width: 24px;
        font-size: 1.35rem;
    }


    #right:hover #custom-system {
    	opacity: 0;
    	min-width: 0;
    	padding: 0;
    	margin: 0;
    }

    #left:hover #custom-info {
    	opacity: 0;
    	min-width: 0;
    	padding: 0;
    	margin: 0;
    }

    #custom-system {
       background-color: #${colors.base00};
       color: #${accentColor};
       padding: 6px 10px;
       border-radius: ${radius}px 0 0 ${radius}px;
       margin: 5px 0 5px 3px;
       border-right: 1px solid #${colors.base03};
       border-left: none;
    }

    #network {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding-top: 4px;
    	padding-bottom: 4px;
    	padding-left: ${left-network-padding};
    	padding-right: ${right-network-padding};
        border-radius: ${radius}px 0 0 ${radius}px;
        margin: 5px 0 5px 3px;
        border-right: 1px solid #${colors.base03};
        border-left: none;
    }

    #pulseaudio {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding: 6px 10px;
        border-radius: 0;
        margin: 5px 0;
        border-right: 1px solid #${colors.base03};
        border-left: none;
    }

    #tray {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding: 6px 10px;
        border-radius: 0;
        margin: 5px 0;
        border-right: 1px solid #${colors.base03};
        border-left: none;
    }

    #clock {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding: 6px 10px;
        border-radius: 0;
        margin: 5px 0;
        border-right: 1px solid #${colors.base03};
        border-left: none;
    }
    #battery {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding: 6px 10px;
        border-radius: 0;
        margin: 5px 0;
        border-right: 1px solid #${colors.base03};
        border-left: none;
    }


    #battery.warning,
    #battery.critical,
    #battery.urgent {
        background-color: #${colors.base09};
        color: #${colors.base00};
        border-radius: 0;
        margin: 5px 0;
        border-right: 1px solid #${colors.base03};
        border-left: none;
    }

    #battery.charging {
        background-color: #${colors.base0B};
        color: #${colors.base00};
        border-radius: 0;
        margin: 5px 0;
        border-right: 1px solid #${colors.base03};
        border-left: none;
    }

    #custom-notification {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding-top: 4px;
        padding-bottom: 4px;
        padding-left: ${left-notification-padding};
        padding-right: ${right-notification-padding};
        border-radius: 0 ${radius}px ${radius}px 0;
        margin: 5px 3px 5px 0;
        border-right: none;
        border-left: none;
        min-width: 24px;
    }

    tooltip {
    	border-radius: ${radius}px;
    	padding: 15px;
        background-color: ${hexToRgba colors.base00 "0.99"};
        border: 2px solid #${colors.base04};
    }

    tooltip label {
    	padding: 5px;
        background-color: ${hexToRgba colors.base00 "0.99"};
        color: #${colors.base05};
      }  
  '';
}
