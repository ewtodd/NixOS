{
  config,
  lib,
  osConfig,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  inherit (inputs.niri-nix.lib) mkNiriKDL;
  deviceType = if (osConfig.systemOptions.deviceType.desktop.enable) then "desktop" else "laptop";
  createKittyPanelService = lib.mkIf (deviceType == "desktop") {
    systemd.user.services.kitty-background-panel = {
      Unit = {
        Description = "Kitty background panel with btop";
        After = [
          "graphical-session.target"
          "niri.service"
        ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.kitty}/bin/kitten panel --edge=center --layer=bottom --class kitty-background --output-name HDMI-A-1 btop";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };

  primaryMonitor = if deviceType == "desktop" then "DP-3" else "eDP-1";
  secondaryMonitor =
    if deviceType == "desktop" then
      "HDMI-A-1"
    else
      (if deviceType == "laptop" then "HDMI-A-2" else "DP-3");
  alt-proportion = if deviceType == "desktop" then 0.5 else 0.75;

  workConfig = {
    workspace = [
      {
        _args = [ "b-chat" ];
        open-on-output = primaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "Slack";
        };
        open-on-workspace = "b-chat";
        default-column-width = {
          proportion = alt-proportion;
        };
        block-out-from = "screencast";
      }
      {
        match._props = {
          app-id = "thunderbird";
        };
        open-on-workspace = "b-chat";
        default-column-width = {
          proportion = alt-proportion;
        };
        block-out-from = "screencast";
      }
      {
        match._props = {
          app-id = "spotify";
        };
        default-column-width = {
          proportion = 1.0;
        };
      }
    ];
    layer-rule = [
      {
        match._props = {
          namespace = "kitty-background";
        };
        place-within-backdrop = true;
      }
    ];
    spawn-sh-at-startup = [
      [ "${pkgs.thunderbird-latest}/bin/thunderbird && niri msg action move-column-left" ]
      [ "sleep 2 && ${pkgs.slack}/bin/slack && niri msg action move-column-right" ]
      [ "${pkgs.protonvpn-gui}/bin/protonvpn-app --start-minimized" ]
    ];

  };

  playConfigBase = {
    workspace = [
      {
        _args = [ "c-chat" ];
        open-on-output = secondaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "signal";
        };
        open-on-workspace = "c-chat";
        default-column-width = {
          proportion = 1.0;
        };
      }
    ];
    layer-rule = [
      {
        match._props = {
          namespace = "kitty-background";
        };
        place-within-backdrop = true;
      }
    ];
    spawn-sh-at-startup = [
      [ "${pkgs.signal-desktop}/bin/signal-desktop --use-tray-icon" ]
      [ "${pkgs.protonvpn-gui}/bin/protonvpn-app --start-minimized" ]
    ];
  };

  playConfigDesktopAdditions = {
    workspace = [
      {
        _args = [ "b-media" ];
        open-on-output = primaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "steam";
        };
        open-on-workspace = "b-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
      {
        match._props = {
          app-id = "spotify";
        };
        open-on-workspace = "b-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
    ];
    spawn-sh-at-startup = [
      [ "sleep 2 && ${pkgs.steam}/bin/steam && niri msg action move-column-left" ]
      [ "sleep 2 && ${pkgs.spotify}/bin/spotify && niri msg action move-column-right" ]
    ];
  };

  playConfig =
    if deviceType == "desktop" then
      {
        workspace = playConfigBase.workspace ++ playConfigDesktopAdditions.workspace;
        window-rule = playConfigBase.window-rule ++ playConfigDesktopAdditions.window-rule;
        layer-rule = playConfigBase.layer-rule ++ playConfigBase.layer-rule;
        spawn-sh-at-startup =
          playConfigBase.spawn-sh-at-startup ++ playConfigDesktopAdditions.spawn-sh-at-startup;
      }
    else
      playConfigBase;
in
{
  config = mkIf (osConfig.systemOptions.owner.e.enable) (mkMerge [
    createKittyPanelService
    {
      xdg.configFile."niri/profile.kdl".text =
        if config.Profile == "work" then
          mkNiriKDL workConfig
        else if config.Profile == "play" then
          mkNiriKDL playConfig
        else
          "";
    }
  ]);
}
