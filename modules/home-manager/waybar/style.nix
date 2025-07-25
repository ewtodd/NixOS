{ config, ... }:

let
  colors = config.colorScheme.palette;
  fontFamily = "JetBrains Mono Nerd Font";
  accentColor = colors.base0E;
  opacity = "0.75";
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
        border-radius: 0 0 8px 8px;
      }

      #workspaces button:first-child {
        border-radius: 8px 0 0 8px;  
        margin-left: 3px;
        border-right: 1px solid #${colors.base03};
      }

      #workspaces {
        background: transparent;
        margin: 6px 0;
        font-size: 1.0rem;
      }

      #workspaces button:first-child:last-child {
        border-radius: 8px;
        margin-left: 3px;
        border-right: none;
      }

      #workspaces button {
        all: initial;
        min-width: 24px;
        padding: 8px 12px;
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

      #workspaces button:last-child {
        border-radius: 0 8px 8px 0;
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

      /* Hidden window module - just for state detection */
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
        padding: 8px 18px;
        margin: 6px 3px;
        border-radius: 8px;
        background-color: #${colors.base00};
        color: #${colors.base0C};
        border: none;
      }

      /* Group 2: Individual modules grouped together */
      #cpu {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding: 8px 12px;
        border-radius: 8px 0 0 8px;
        margin: 6px 0 6px 3px;
        border-right: 1px solid #${colors.base03};
        border-left: none;
      }

      #memory {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding: 8px 12px;
        border-radius: 0;
        margin: 6px 0;
        border-right: 1px solid #${colors.base03};
        border-left: none;
      }
       
       #network {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding-top: 8px;
        padding-bottom: 8px;
        padding-left: 8px;
        padding-right: 13px;
        border-radius: 0;
        margin: 6px 0;
        border-right: 1px solid #${colors.base03};
        border-left: none;
      }


      #pulseaudio {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding: 8px 12px;
        border-radius: 0;
        margin:  6px 0;
        border-right: 1px solid #${colors.base03}; 
        border-left: none;
     }

    #battery {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding: 8px 12px;
        border-radius: 0;  /* No longer rounded on right */ 
        margin: 6px 0;     /* No longer has right margin */ 
        border-right: 1px solid #${colors.base03};  /* Now has right border */ 
        border-left: none;
        border-right: 1px solid #${colors.base03};  /* Now has right border */ 
      }
      
      #battery.warning,
      #battery.critical,
      #battery.urgent {
        background-color: #${colors.base09};
        color: #${colors.base00};
        border-radius: 0;  /* No longer rounded on right */ 
        margin: 6px 0;     /* No longer has right margin */ 
        border-right: 1px solid #${colors.base03};  /* Now has right border */ 
      } 
      #battery.charging { 
        background-color: #${colors.base0B}; 
        color: #${colors.base00}; 
        border-radius: 0;  /* No longer rounded on right */ 
        margin: 6px 0;     /* No longer has right margin */ 
        border-right: 1px solid #${colors.base03};  /* Now has right border */ 
      }
      #custom-notification {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding-top: 8px;
        padding-bottom: 8px;
        padding-left: 8px;
        padding-right: 12px;  /* Increased right padding */ 
        border-radius: 0 8px 8px 0;  /* Now rounded on right */ 
        margin: 6px 3px 6px 0;  /* Now has right margin */ 
        border-right: none;/* No right border since it's last */ 
        border-left: none; 
        min-width: 24px; 
      }
      /* Group 3: Clock + Notification + Tray */
      #clock {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding: 8px 12px;
        border-radius: 8px 0 0 8px;
        margin: 6px 0 6px 3px;
        border-right: 1px solid #${colors.base03};
        border-left: none;
      }

      

      #tray {
        background-color: #${colors.base00};
        color: #${accentColor};
        padding: 8px 12px;
        border-radius: 0 8px 8px 0;
        margin: 6px 3px 6px 0;
        border-left: none;
        border-right: none;
      }

      /* Tooltips */
      tooltip {
        border-radius: 8px;
        padding: 15px;
        background-color: #${colors.base00};
      }

      tooltip label {
        padding: 5px;
        background-color: #${colors.base00};
        color: #${colors.base05};
      }
  '';
}
