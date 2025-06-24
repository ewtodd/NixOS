{ config, pkgs, ... }:

{
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
      control-center-width = 600; # Increased width for calendar
      control-center-height = 700; # Increased height
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
        background-color: rgba(24, 24, 37, 0.95);
        border: 1px solid rgba(205, 214, 244, 0.2);
        border-radius: 12px;
        margin: 18px;
        padding: 12px;
      }

      .control-center-list {
        background-color: transparent;
      }

      .notification {
        background-color: rgba(30, 30, 46, 0.9);
        border: 1px solid rgba(205, 214, 244, 0.1);
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
        color: #cdd6f4;
        background-color: transparent;
      }

      .time {
        font-size: 12px;
        color: #a6adc8;
        margin-right: 18px;
        background-color: transparent;
      }

      .body {
        font-size: 13px;
        color: #bac2de;
        background-color: transparent;
      }

      .widget-title {
        color: #cdd6f4;
        background-color: rgba(30, 30, 46, 0.9);
        padding: 8px 12px;
        margin: 6px 0;
        border-radius: 8px;
        border: 1px solid rgba(205, 214, 244, 0.1);
      }

      .widget-title > button {
        font-size: 12px;
        color: #f38ba8;
        text-shadow: none;
        background-color: transparent;
        border: 1px solid #f38ba8;
        border-radius: 4px;
        padding: 4px 8px;
      }

      .widget-title > button:hover {
        background-color: rgba(243, 139, 168, 0.15);
      }

      .widget-dnd {
        background-color: rgba(30, 30, 46, 0.9);
        border: 1px solid rgba(205, 214, 244, 0.1);
        border-radius: 8px;
        margin: 6px 0;
        padding: 8px;
        color: #cdd6f4;
      }

      .widget-dnd > switch {
        background-color: #313244;
        border-radius: 8px;
      }

      .widget-dnd > switch:checked {
        background-color: rgba(243, 139, 168, 0.8);
      }

      /* Calendar Widget Styling */
      .widget-calendar {
        background-color: rgba(30, 30, 46, 0.9);
        border: 1px solid rgba(205, 214, 244, 0.1);
        border-radius: 8px;
        margin: 6px 0;
        padding: 12px;
        color: #cdd6f4;
      }

      .widget-calendar .calendar-date {
        font-size: 16px;
        font-weight: bold;
        text-align: center;
        margin-bottom: 8px;
        color: #cdd6f4;
      }

      .widget-calendar calendar {
        background-color: transparent;
        border: none;
        color: #cdd6f4;
      }

      .widget-calendar calendar:selected {
        background-color: rgba(203, 166, 247, 0.3);
        color: #cdd6f4;
        border-radius: 4px;
      }

      .widget-calendar calendar:indeterminate {
        color: #6c7086;
      }
    '';
  };
}
