{ config, pkgs, lib, ... }:

with lib;

let
  colors = config.colorScheme.palette;
  profile = config.Profile;
in {
  services.swaync = {
    enable = true;
    settings = {
      positionX = "center";
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
      control-center-height = 700;
      notification-window-width = 500;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
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
        background-color: #${colors.base00}f2;
        border: 1px solid #${colors.base05}33;
        border-radius: 12px;
        margin: 18px;
        padding: 12px;
      }

      .control-center-list {
        background-color: transparent;
      }

      .notification {
        background-color: #${colors.base01}e6;
        border: 1px solid #${colors.base05}1a;
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
        background-color: #${colors.base01}e6;
        padding: 8px 12px;
        margin: 6px 0;
        border-radius: 8px;
        border: 1px solid #${colors.base05}1a;
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
        background-color: #${colors.base08}26;
      }

      .widget-dnd {
        background-color: #${colors.base01}e6;
        border: 1px solid #${colors.base05}1a;
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
        background-color: #${colors.base08}cc;
      }

      .widget-calendar {
        background-color: #${colors.base01}e6;
        border: 1px solid #${colors.base05}1a;
        border-radius: 8px;
        margin: 6px 0;
        padding: 12px;
        color: #${colors.base05};
      }

      .widget-calendar .calendar-date {
        font-size: 16px;
        font-weight: bold;
        text-align: center;
        margin-bottom: 8px;
        color: #${colors.base05};
      }

      .widget-calendar calendar {
        background-color: transparent;
        border: none;
        color: #${colors.base05};
      }

      .widget-calendar calendar:selected {
        background-color: #${colors.base0E}4d;
        color: #${colors.base05};
        border-radius: 4px;
      }

      .widget-calendar calendar:indeterminate {
        color: #${colors.base03};
      }
    '';
  };
}
