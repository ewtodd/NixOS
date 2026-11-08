{
  osConfig ? null,
  config,
  lib,
  ...
}:
let
  hostname = if osConfig != null then osConfig.networking.hostName else "HOSTNAME_PLACEHOLDER";
  wallpaperPath = config.WallpaperPath or "/etc/nixos/hosts/${hostname}/wallpaper.png";
  e = if osConfig != null then (osConfig.systemOptions.owner.e.enable or false) else false;
  deviceType =
    if osConfig != null && (osConfig.systemOptions.deviceType.desktop.enable or false) then
      "desktop"
    else
      "laptop";
  opacity = 0.9;
in
{
  imports = [
    ./palette.nix
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "fleet";
        templates.enable_community_templates = false;
      };
      wallpaper = {
        enabled = true;
        directory = dirOf wallpaperPath;
        default.path = wallpaperPath;
      };
      backdrop.enabled = true;
      shell = {
        avatar_path = wallpaperPath;
        screen_time_enabled = true;
        session.actions = [
          {
            action = "lock";
            countdown_seconds = 5.0;
            enabled = true;
            shortcut = "l";
            variant = "default";
          }
          {
            action = "logout";
            countdown_seconds = 5.0;
            enabled = true;
            shortcut = "x";
            variant = "default";
          }
          {
            action = "reboot";
            countdown_seconds = 5.0;
            enabled = true;
            shortcut = "r";
            variant = "default";
          }
          {
            action = "shutdown";
            countdown_seconds = 5.0;
            enabled = true;
            shortcut = "p";
            variant = "default";
          }
        ];
        clipboard_enabled = false;
        time_format = "%I:%M %p";
        launcher = {
          app_grid = true;
          auto_paste = "off";
          compact = true;
          default_view = "all";
          fetch_exchange_rates = false;
        };
        panel.launcher_placement = "attached";
      };
      location.address = "Woodridge, IL";
      nightlight = {
        enabled = true;
        temperature_night = 5000;
      };
      notification = {
        background_opacity = opacity;
        keep_dismissed_in_history = false;
      };
      osd = {
        background_opacity = opacity;
        border_width = 2.0;
        follow_focused_output = true;
        position = "top_right";
        position_vertical = "top_right";
      };
      bar.default = {
        position = lib.mkIf e "right";
        monitor.HDMI-A-2.enabled = lib.mkIf e false;
        reserve_space = true;
        background_opacity = opacity;
        margin_ends = 200;
        start = [ "workspaces" ];
        center = [
          "clock"
          "spacer_0"
          "notifications"
        ];
        end = [
          "tray"
          "network"
          "bluetooth"
        ]
        ++ lib.optionals (deviceType == "laptop") [ "battery" ]
        ++ [
          "caffeine"
          "control-center"
        ];
        font_family = "Ubuntu Nerd Font";
      };
      control_center = {
        circular_avatar = false;
        hidden_tabs = [
          "media"
          "monitor"
          "system"
          "power"
          "network"
          "bluetooth"
          "notifications"
        ];
      };
      desktop_widgets = {
        enabled = false;
        schema_version = 2;
        widget_order = [ ];
        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };
      };
      lockscreen = {
        blurred_desktop = true;
        transition = [ "fade" ];
        transition_duration = 1000;
      };
      lockscreen_widgets = {
        enabled = true;
        schema_version = 2;
        widget_order = [
          "lockscreen-login-box@eDP-1"
          "lockscreen-login-box@DP-3"
          "lockscreen-login-box@HDMI-A-2"
        ];
        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };
        widget."lockscreen-login-box@eDP-1" = {
          settings.layout = "compact";
          type = "login_box";
          box_height = 70.0;
          box_width = 400.0;
          cx = 836.0;
          cy = 557.0;
          output = "eDP-1";
          placement_height = 1114.0;
          placement_width = 1671.0;
          rotation = 0.0;
        };
        widget."lockscreen-login-box@DP-3" = {
          settings.layout = "compact";
          type = "login_box";
          box_height = 70.0;
          box_width = 400.0;
          cx = 1720.0;
          cy = 755.0;
          output = "DP-3";
          placement_height = 1114.0;
          placement_width = 3440.0;
          rotation = 0.0;
        };
        widget."lockscreen-login-box@HDMI-A-2" = {
          settings.layout = "compact";
          type = "login_box";
          box_height = 70.0;
          box_width = 400.0;
          cx = 540.0;
          cy = 1742.0;
          output = "HDMI-A-2";
          placement_height = 1920.0;
          placement_width = 1080.0;
          rotation = 0.0;
          enabled = false;
        };

      };
      weather.unit = "imperial";
      widget = {
        control-center.glyph = "server-cog";
        network.show_label = false;
        clock.format = "{:%a %d %b %I:%M %p}";
        clock.vertical_format = "{:%I\\n%M\\n—\\n%m\\n%d}";
        clock.anchor = true;
        spacer_0.length = 15;
        spacer_0.type = "spacer";
        workspaces = {
          active_pill_size = 2.5;
          hide_when_empty = true;
          inactive_pill_size = 1.4;
          show_labels = false;
          show_tooltip = false;
          empty_color = "primary_container";
          occupied_color = "tertiary";
        };
      };
    };
  };
}
