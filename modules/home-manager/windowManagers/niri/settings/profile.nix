{ config, lib, osConfig, pkgs, ... }:

with lib;
let
  primaryMonitor = if osConfig.DeviceType == "desktop" then "DP-3" else "eDP-1";
  secondaryMonitor = if osConfig.DeviceType == "desktop" then
    "HDMI-A-1"
  else
    (if osConfig.DeviceType == "laptop" then "HDMI-A-2" else "DP-3");
  alt-proportion = if osConfig.DeviceType == "desktop" then "0.5" else "0.75";
in {

  xdg.configFile."niri/profile.kdl".text =
    mkIf (lib.strings.hasPrefix "e" osConfig.networking.hostName) (mkMerge [
      (mkIf (config.Profile == "work") ''
        workspace "b-chat" {
          open-on-output "${primaryMonitor}"
        }
        workspace "c-calendar" {
          open-on-output "${secondaryMonitor}"
        }
        window-rule {
          match app-id="Slack"
          match app-id="thunderbird"
          open-on-workspace "b-chat"
          default-column-width { proportion ${alt-proportion}; }
          block-out-from "screencast"
        }
        window-rule {
          match app-id="firefox"
          default-column-width { proportion ${alt-proportion}; }
        }
        window-rule {
          match app-id="Todoist" 
          open-on-workspace "c-calendar"
          default-column-width { proportion 1.0; }
        }
        spawn-sh-at-startup "${pkgs.thunderbird-latest}/bin/thunderbird && niri msg action move-column-left"
        spawn-sh-at-startup "sleep 2 && ${pkgs.slack}/bin/slack && niri msg action move-column-right"
        spawn-sh-at-startup "sleep 2 && ${pkgs.todoist-electron}/bin/todoist-electron"
      '')
      (mkIf (config.Profile == "play") ''
        workspace "b-media" {
          open-on-output "${primaryMonitor}"
        }
        workspace "c-chat" {
          open-on-output "${secondaryMonitor}"
        }
        window-rule {
          match app-id="steam"
          match app-id="spotify"
          open-on-workspace "b-media"
          default-column-width { proportion ${alt-proportion}; }
        }
        window-rule {
          match app-id="firefox"
          default-column-width { proportion ${alt-proportion}; }
        }
        window-rule {
          match app-id="signal" 
          open-on-workspace "c-chat"
          default-column-width { proportion 1.0; }
        }
        spawn-sh-at-startup "${pkgs.signal-desktop}/bin/signal-desktop --use-tray-icon"
        spawn-sh-at-startup "sleep 2 && ${pkgs.steam}/bin/steam && niri msg action move-column-left"
        spawn-sh-at-startup "sleep 2 && ${pkgs.spotify}/bin/spotify && niri msg action move-column-right"
      '')
    ]);
}
