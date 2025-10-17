{ config, osConfig, pkgs, lib, ... }:

with lib;

let
  colors = config.colorScheme.palette;
  profile = config.Profile;
  deviceType = osConfig.DeviceType;

  # Font selection based on profile
  fontFamily = config.FontChoice;

  # Scale font sizes for laptop with fractional scaling
  baseFontSize = 32;
  fontSize = if deviceType == "laptop" then 42 else baseFontSize;

  # Logo selection based on profile
  logoPath = if profile == "play" then
    "/etc/nixos/modules/home-manager/windowManagers/sway/services/nixos-eris.png"
  else
    "/etc/nixos/modules/home-manager/windowManagers/sway/services/nixos_kanagawa.png";

in {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;

    settings = {
      screenshots = true;
      effect-blur = "7x7";
      effect-compose = "50%,77%;center;${logoPath}";

      # Hide indicator until typing begins
      indicator-idle-visible = false;
      indicator-y-position = "300";

      # Clock configuration
      clock = true;
      timestr = "%-I:%M %p";
      datestr = "%a, %b %d";
      font = fontFamily;
      font-size = fontSize;
      indicator-radius = 20;
      show-failed-attempts = true;
      ignore-empty-password = true;
      daemonize = true;
      fade = 5;
      grace = 5;

      # Dynamic color scheme using nix-colors - note the # prefix
      color = "#${colors.base00}";

      # Text colors
      text-color = "#${colors.base05}";
      text-clear-color = "#${colors.base0B}";
      text-caps-lock-color = "#${colors.base0A}";
      text-ver-color = "#${colors.base0E}";
      text-wrong-color = "#${colors.base08}";

      # Highlight colors
      bs-hl-color = "#${colors.base03}66";
      key-hl-color = "#${colors.base0C}";
      caps-lock-bs-hl-color = "#${colors.base03}66";
      caps-lock-key-hl-color = "#${colors.base0A}";
      separator-color = "#${colors.base04}";

      # Inside colors (with transparency)
      inside-color = "#${colors.base00}55";
      inside-clear-color = "#${colors.base0B}55";
      inside-caps-lock-color = "#${colors.base0A}55";
      inside-ver-color = "#${colors.base0E}55";
      inside-wrong-color = "#${colors.base08}55";

      # Line colors
      line-color = "#${colors.base03}";
      line-clear-color = "#${colors.base0B}";
      line-caps-lock-color = "#${colors.base0A}";
      line-ver-color = "#${colors.base0E}";
      line-wrong-color = "#${colors.base08}";

      # Ring colors (with transparency)
      ring-color = "#${colors.base04}aa";
      ring-clear-color = "#${colors.base0B}aa";
      ring-caps-lock-color = "#${colors.base0A}aa";
      ring-ver-color = "#${colors.base0E}aa";
      ring-wrong-color = "#${colors.base08}aa";
    };
  };
}
