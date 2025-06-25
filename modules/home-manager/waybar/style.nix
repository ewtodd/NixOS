
{ config, lib, pkgs, ... }:

let
  colors = config.colorScheme.palette;
  profile = config.Profile;
  fontFamily = if profile == "work" then "FiraCode Nerd Font" else "JetBrains Mono Nerd Font";
in
{
  programs.waybar.style = ''
    * {
      border: none;
      border-radius: 0;
      min-height: 0;
      font-family: "${fontFamily}";
      font-size: 0.9rem;
    }

    /* Default transparent background when no windows */
    window#waybar {
      background: none;
      border: none;
      box-shadow: none;
    }

    /* Solid background when windows are present */
    window#waybar:not(.empty) {
      background-color: #${colors.base00};
      border-radius: 0;
    }

    /* Group 1: Logo + Workspaces */
    #custom-logo {
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 2px;
      padding-right: 5px;
      margin-left: 0px;
      margin-right: 0px;
      font-size: 22px;
      border-radius: 8px 0 0 8px;
      color: #${colors.base0E};
      min-width: 30px;
      background-color: #${colors.base00};
      margin: 6px 0 6px 3px;
      border-right: 1px solid #${colors.base03};
      border-left: none;
    }

    #workspaces {
      background: transparent;
      margin: 6px 0;
    }

    #workspaces button {
      all: initial;
      min-width: 24px;
      padding: 8px 12px;
      margin: 0;
      border-radius: 0;
      background-color: #${colors.base00};
      color: #${colors.base0E};
      transition: background 0.2s, color 0.2s;
      border-left: none;
    }

    #workspaces button:not(:last-child) {
      border-right: 1px solid #${colors.base03};
    }

    #workspaces button:last-child {
      border-radius: 0 8px 8px 0;
      border-right: none;
    }

    #workspaces button.active,
    #workspaces button:hover {
      color: #${colors.base00};
      background-color: #${colors.base0E};
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
      color: #${colors.base0E};
      padding: 8px 12px;
      border-radius: 8px 0 0 8px;
      margin: 6px 0 6px 3px;
      border-right: 1px solid #${colors.base03};
      border-left: none;
    }

    #memory,
    #battery,
    #backlight,
    #pulseaudio {
      background-color: #${colors.base00};
      color: #${colors.base0E};
      padding: 8px 12px;
      border-radius: 0;
      margin: 6px 0;
      border-right: 1px solid #${colors.base03};
      border-left: none;
    }

    #network {
      background-color: #${colors.base00};
      color: #${colors.base0E};
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 8px;
      padding-right: 12px;
      border-radius: 0;
      margin: 6px 0;
      border-right: 1px solid #${colors.base03};
      border-left: none;
    }

    #custom-power {
      background-color: #${colors.base00};
      color: #${colors.base0E};
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 8px;
      padding-right: 10px;
      border-radius: 0 8px 8px 0;
      margin: 6px 3px 6px 0;
      border-left: none;
      border-right: none;
    }

    /* Special states for battery */
    #battery.warning,
    #battery.critical,
    #battery.urgent {
      background-color: #${colors.base09};
      color: #${colors.base00};
      border-right: 1px solid #${colors.base03};
    }

    #battery.charging {
      background-color: #${colors.base0B};
      color: #${colors.base00};
      border-right: 1px solid #${colors.base03};
    }

    /* Group 3: Clock + Notification + Tray */
    #clock {
      background-color: #${colors.base00};
      color: #${colors.base0E};
      padding: 8px 12px;
      border-radius: 8px 0 0 8px;
      margin: 6px 0 6px 3px;
      border-right: 1px solid #${colors.base03};
      border-left: none;
    }

    #custom-notification {
      background-color: #${colors.base00};
      font-size: 15px;
      color: #${colors.base0E};
      padding-top: 8px;
      padding-bottom: 8px;
      padding-left: 8px;
      padding-right: 10px;
      border-radius: 0;
      margin: 6px 0;
      border-right: 1px solid #${colors.base03};
      border-left: none;
      min-width: 24px;
    }

    #tray {
      background-color: #${colors.base00};
      color: #${colors.base0E};
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

