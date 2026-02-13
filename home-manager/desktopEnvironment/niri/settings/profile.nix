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
  primaryMonitor = if deviceType == "desktop" then "DP-3" else "eDP-1";
  secondaryMonitor =
    if deviceType == "desktop" then
      "HDMI-A-1"
    else
      (if deviceType == "laptop" then "HDMI-A-2" else "DP-3");
  alt-proportion = if deviceType == "desktop" then 0.5 else 0.75;
  home = config.home.homeDirectory;
  wrap = inputs.nix-wrap.lib.${pkgs.stdenv.hostPlatform.system}.wrap;
  themeArgs = "-r ${home}/.config/gtk-3.0 -r ${home}/.config/gtk-4.0 -r ${home}/.config/dconf";
  wrapped-slack = pkgs.slack;
  wrapped-signal = pkgs.signal-desktop;
  wrapped-spotify = wrap {
    package = pkgs.spotify;
    executable = "spotify";
    wrapArgs = "-d -n -a -b -p -w ${home}/.config/spotify -w ${home}/.cache/spotify -r ${home}/.config/dconf";
  };
  wrapped-thunderbird = wrap {
    package = pkgs.thunderbird;
    executable = "thunderbird";
    wrapArgs = "-d -n -a -b -p -w ${home}/.thunderbird -w ${home}/Downloads ${themeArgs}";
  };

  workConfigBase = {
    workspace = [
      {
        _args = [ "a-chat" ];
        open-on-output = primaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "Slack";
        };
        open-on-workspace = "a-chat";
        default-column-width = {
          proportion = alt-proportion;
        };
        block-out-from = "screencast";
      }
      {
        match._props = {
          app-id = "thunderbird";
        };
        open-on-workspace = "a-chat";
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
    spawn-sh-at-startup = [
      [ "sleep 2 && ${wrapped-thunderbird}/bin/thunderbird && niri msg action move-column-left" ]
      [ "sleep 2 && ${wrapped-slack}/bin/slack && niri msg action move-column-right" ]
      [ "${pkgs.protonvpn-gui}/bin/protonvpn-app --start-minimized" ]
    ];

  };

  workConfigDesktopAdditions = {
    workspace = [
      {
        _args = [ "b-btop" ];
        open-on-output = secondaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "btopkitty";
        };
        open-on-workspace = "b-btop";
        open-fullscreen = true;
      }
    ];
    spawn-sh-at-startup = [
      [ "${pkgs.kitty}/bin/kitty --class btopkitty btop" ]
    ];
  };

  playConfigBase = {
    workspace = [
      {
        _args = [ "b-chat" ];
        open-on-output = secondaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "signal";
        };
        open-on-workspace = "b-chat";
        default-column-width = {
          proportion = 1.0;
        };
      }
    ];
    spawn-sh-at-startup = [
      [ "${wrapped-signal}/bin/signal-desktop --use-tray-icon" ]
      [ "${pkgs.protonvpn-gui}/bin/protonvpn-app --start-minimized" ]
    ];
  };

  playConfigDesktopAdditions = {
    workspace = [
      {
        _args = [ "a-media" ];
        open-on-output = primaryMonitor;
      }
      {
        _args = [ "c-btop" ];
        open-on-output = secondaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "steam";
        };
        open-on-workspace = "a-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
      {
        match._props = {
          app-id = "spotify";
        };
        open-on-workspace = "a-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
      {
        match._props = {
          app-id = "btopkitty";
        };
        open-on-workspace = "c-btop";
        open-fullscreen = true;
      }

    ];
    spawn-sh-at-startup = [
      [ "sleep 2 && ${pkgs.steam}/bin/steam && niri msg action move-column-left" ]
      [ "sleep 2 && ${wrapped-spotify}/bin/spotify && niri msg action move-column-right" ]
      [ "${pkgs.kitty}/bin/kitty --class btopkitty btop" ]
    ];
  };

  playConfig =
    if deviceType == "desktop" then
      {
        workspace = playConfigBase.workspace ++ playConfigDesktopAdditions.workspace;
        window-rule = playConfigBase.window-rule ++ playConfigDesktopAdditions.window-rule;
        spawn-sh-at-startup =
          playConfigBase.spawn-sh-at-startup ++ playConfigDesktopAdditions.spawn-sh-at-startup;
      }
    else
      playConfigBase;

  workConfig =
    if deviceType == "desktop" then
      {
        workspace = workConfigBase.workspace ++ workConfigDesktopAdditions.workspace;
        window-rule = workConfigBase.window-rule ++ workConfigDesktopAdditions.window-rule;
        spawn-sh-at-startup =
          workConfigBase.spawn-sh-at-startup ++ workConfigDesktopAdditions.spawn-sh-at-startup;
      }
    else
      workConfigBase;
in
{
  config = mkIf (osConfig.systemOptions.owner.e.enable) (mkMerge [
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
