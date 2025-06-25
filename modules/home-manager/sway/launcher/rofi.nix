{ config, pkgs, lib, ... }:

with lib;

let
  colors = config.colorScheme.palette;
  profile = config.Profile;

  # Font selection based on profile
  fontFamily = if profile == "work" then
    "FiraCode Nerd Font"
  else
    "JetBrains Mono Nerd Font";
  fontSize = "14";

  # Icon theme based on profile
  iconTheme = if profile == "work" then "Papirus-Light" else "Dracula";

in {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.kitty}/bin/kitty";

    extraConfig = {
      modi = "drun";
      show-icons = true;
      display-drun = " ";
      drun-display-format = "{name}";
      font = "${fontFamily}:weight=bold:size=${fontSize}";
      icon-theme = iconTheme;
    };
  };

  # Dynamic theme based on nix-colors
  xdg.configFile."rofi/themes/nix-colors-grid.rasi".text = ''
    /**
     * ROFI Color theme
     * Generated from nix-colors
     */
    * {
      background-color: #${colors.base00};
      border-color: #${colors.base00};
      text-color: #${colors.base05};
      selection-background-color: #${colors.base02};
      selection-text-color: #${colors.base05};
      separatorcolor: #${colors.base00};
      urgent-background-color: #${colors.base08};
      urgent-text-color: #${colors.base00};
      active-background-color: #${colors.base0D};
      active-text-color: #${colors.base00};
    }

    configuration {
      modi: "drun";
      show-icons: true;
      display-drun: " ";
      drun-display-format: "{name}";
      font: "${fontFamily}:weight=bold:size=${fontSize}";
      icon-theme: "${iconTheme}";
    }

    window {
      transparency: "real";
      background-color: #${colors.base00}bf;
      text-color: #${colors.base05};
      border: 0px;
      border-color: #${colors.base03};
      border-radius: 0px;
      width: 100%;
      height: 100%;
      location: center;
      anchor: center;
      fullscreen: true;
      x-offset: 0px;
      y-offset: 0px;
      cursor: "default";
    }

    mainbox {
      background-color: transparent;
      border: 0px;
      border-radius: 0px;
      border-color: #${colors.base03};
      children: [ "inputbar", "listview" ];
      spacing: 100px;
      padding: 100px 225px;
    }

    inputbar {
      children: [ "prompt", "entry" ];
      background-color: #${colors.base00}1a;
      text-color: #${colors.base05};
      expand: false;
      border: 2px solid;
      border-radius: 10px;
      border-color: #${colors.base03};
      margin: 0% 25%;
      padding: 18px;
      spacing: 10px;
    }

    prompt {
      enabled: true;
      background-color: transparent;
      text-color: #${colors.base0E};
    }

    entry {
      background-color: transparent;
      text-color: #${colors.base05};
      cursor: text;
      placeholder: "Search";
      placeholder-color: #${colors.base03};
    }

    listview {
      background-color: transparent;
      columns: 8;
      lines: 4;
      spacing: 0px;
      cycle: true;
      dynamic: true;
      layout: vertical;
      reverse: false;
      scrollbar: false;
      fixed-height: true;
      fixed-columns: true;
      border: 0px;
      border-radius: 0px;
      border-color: #${colors.base03};
      cursor: "default";
    }

    element {
      background-color: transparent;
      text-color: #${colors.base05};
      orientation: vertical;
      border-radius: 15px;
      padding: 35px 10px;
      spacing: 15px;
      cursor: pointer;
    }

    element normal.normal {
      background-color: transparent;
      text-color: #${colors.base05};
    }

    element normal.urgent {
      background-color: #${colors.base08};
      text-color: #${colors.base00};
    }

    element normal.active {
      background-color: #${colors.base0D};
      text-color: #${colors.base00};
    }

    element selected.normal {
      background-color: #${colors.base02};
      text-color: #${colors.base05};
      border: 2px solid;
      border-color: #${colors.base03};
    }

    element selected.urgent {
      background-color: #${colors.base08};
      text-color: #${colors.base00};
    }

    element selected.active {
      background-color: #${colors.base0D};
      text-color: #${colors.base00};
    }

    element-icon {
      background-color: transparent;
      text-color: inherit;
      size: 72px;
      cursor: inherit;
    }

    element-text {
      background-color: transparent;
      text-color: inherit;
      expand: true;
      horizontal-align: 0.5;
      vertical-align: 0.5;
      margin: 0px 2px 0px 2px;
      cursor: inherit;
    }

    scrollbar {
      width: 4px;
      border: 0px;
      handle-color: #${colors.base03};
      handle-width: 8px;
      padding: 0px;
    }

    sidebar {
      border: 0px;
      border-color: #${colors.base03};
      border-radius: 0px;
    }

    button {
      cursor: pointer;
      background-color: transparent;
      text-color: #${colors.base05};
    }

    button selected {
      background-color: #${colors.base02};
      text-color: #${colors.base05};
    }

    message {
      border: 0px;
      border-color: #${colors.base03};
      padding: 100px;
    }

    textbox {
      text-color: #${colors.base05};
      background-color: transparent;
    }
  '';

  # Set the custom theme as default
  xdg.configFile."rofi/config.rasi".text = ''
    @theme "nix-colors-grid"
  '';
}
