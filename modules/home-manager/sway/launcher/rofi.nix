{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.kitty}/bin/kitty";

    extraConfig = {
      modi = "drun";
      show-icons = true;
      display-drun = "  ";
      drun-display-format = "{name}";
      font = "JetBrains Mono NF:weight=bold:size=14";
      icon-theme = "Dracula";
    };
  };
  _module.args.launcherCommand = "rofi -show drun -matching fuzzy";

  # Download and configure the official Dracula theme
  xdg.configFile."rofi/themes/dracula-grid.rasi".text = ''
    /**
     * ROFI Color theme
     * User: Dracula
     * Copyright: Dracula Theme
     */

    * {
        background-color:            #282a36;
        border-color:                #282a36;
        text-color:                  #f8f8f2;
        selection-background-color:  #44475a;
        selection-text-color:        #f8f8f2;
        separatorcolor:              #282a36;
        urgent-background-color:     #ff5555;
        urgent-text-color:           #f8f8f2;
        active-background-color:     #bd93f9;
        active-text-color:           #f8f8f2;
    }

    configuration {
        modi:                        "drun";
        show-icons:                  true;
        display-drun:                "  ";
        drun-display-format:         "{name}";
        font:                        "JetBrains Mono NF:weight=bold:size=14";
        icon-theme:                  "Dracula";
    }

    window {
        transparency:                "real";
        background-color:            #282a36bf;
        text-color:                  #f8f8f2;
        border:                      0px;
        border-color:                #6272a4;
        border-radius:               0px;
        width:                       100%;
        height:                      100%;
        location:                    center;
        anchor:                      center;
        fullscreen:                  true;
        x-offset:                    0px;
        y-offset:                    0px;
        cursor:                      "default";
    }

    mainbox {
        background-color:            transparent;
        border:                      0px;
        border-radius:               0px;
        border-color:                #6272a4;
        children:                    [ "inputbar", "listview" ];
        spacing:                     100px;
        padding:                     100px 225px;
    }

    inputbar {
        children:                    [ "prompt", "entry" ];
        background-color:            rgba(40, 42, 54, 0.1);
        text-color:                  #f8f8f2;
        expand:                      false;
        border:                      2px solid;
        border-radius:               10px;
        border-color:                #6272a4;
        margin:                      0% 25%;
        padding:                     18px;
        spacing:                     10px;
    }

    prompt {
        enabled:                     true;
        background-color:            transparent;
        text-color:                  #ff79c6;
    }

    entry {
        background-color:            transparent;
        text-color:                  #f8f8f2;
        cursor:                      text;
        placeholder:                 "Search";
        placeholder-color:           #6272a4;
    }

    listview {
        background-color:            transparent;
        columns:                     8;
        lines:                       4;
        spacing:                     0px;
        cycle:                       true;
        dynamic:                     true;
        layout:                      vertical;
        reverse:                     false;
        scrollbar:                   false;
        fixed-height:                true;
        fixed-columns:               true;
        border:                      0px;
        border-radius:               0px;
        border-color:                #6272a4;
        cursor:                      "default";
    }

    element {
        background-color:            transparent;
        text-color:                  #f8f8f2;
        orientation:                 vertical;
        border-radius:               15px;
        padding:                     35px 10px;
        spacing:                     15px;
        cursor:                      pointer;
    }

    element normal.normal {
        background-color:            transparent;
        text-color:                  #f8f8f2;
    }

    element normal.urgent {
        background-color:            #ff5555;
        text-color:                  #f8f8f2;
    }

    element normal.active {
        background-color:            #bd93f9;
        text-color:                  #f8f8f2;
    }

    element selected.normal {
        background-color:            #44475a;
        text-color:                  #f8f8f2;
        border:                      2px solid;
        border-color:                #6272a4;
    }

    element selected.urgent {
        background-color:            #ff5555;
        text-color:                  #f8f8f2;
    }

    element selected.active {
        background-color:            #bd93f9;
        text-color:                  #f8f8f2;
    }

    element-icon {
        background-color:            transparent;
        text-color:                  inherit;
        size:                        72px;
        cursor:                      inherit;
    }

    element-text {
        background-color:            transparent;
        text-color:                  inherit;
        expand:                      true;
        horizontal-align:            0.5;
        vertical-align:              0.5;
        margin:                      0px 2px 0px 2px;
        cursor:                      inherit;
    }

    scrollbar {
        width:                       4px;
        border:                      0px;
        handle-color:                #6272a4;
        handle-width:                8px;
        padding:                     0px;
    }

    sidebar {
        border:                      0px;
        border-color:                #6272a4;
        border-radius:               0px;
    }

    button {
        cursor:                      pointer;
        background-color:            transparent;
        text-color:                  #f8f8f2;
    }

    button selected {
        background-color:            #44475a;
        text-color:                  #f8f8f2;
    }

    message {
        border:                      0px;
        border-color:                #6272a4;
        padding:                     100px;
    }

    textbox {
        text-color:                  #f8f8f2;
        background-color:            transparent;
    }
  '';

  # Set the custom theme as default
  xdg.configFile."rofi/config.rasi".text = ''
    @theme "dracula-grid"
  '';
}
