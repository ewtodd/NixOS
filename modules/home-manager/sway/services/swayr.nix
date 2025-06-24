{ config, pkgs, ... }: {
  programs.swayr = {
    enable = true;
    settings = {
      menu = {
        executable = "${pkgs.fuzzel}/bin/fuzzel";
        args = [
          "--dmenu"
          "--prompt= " # Window emoji for visual appeal
          "--lines=15"
          "--width=80"
          "--horizontal-pad=20"
          "--vertical-pad=10"
          "--inner-pad=5"
          "--border-radius=12"
          "--border-width=1"
          "--font=JetBrains Mono NF:weight=bold:size=14"
          "--background-color=282a36bf"
          "--text-color=f8f8f2ff"
          "--selection-color=44475aff"
          "--selection-text-color=f8f8f2ff"
          "--border-color=6272a4ff"
          "--match-color=ffb86cff"
          "--prompt-color=ff79c6ff"
        ];
      };
      format = {
        output_format = "{indent}Output {name}";
        workspace_format =
          "{indent}Workspace {name} [{layout}] on {output_name}";
        container_format =
          "{indent}Container [{layout}] on workspace {workspace_name}";
        window_format =
          "{app_name} — {title} on workspace {workspace_name}u0000iconu001f{app_icon}";
        indent = " ";
        html_escape = false;
      };
      layout = {
        auto_tile = false;
        auto_tile_min_window_width_per_output_width = [
          [ 800 400 ]
          [ 1024 500 ]
          [ 1280 600 ]
          [ 1400 680 ]
          [ 1440 700 ]
          [ 1600 780 ]
          [ 1680 780 ]
          [ 1920 920 ]
          [ 2048 980 ]
          [ 2560 1000 ]
          [ 3440 1200 ]
          [ 3840 1280 ]
          [ 4096 1400 ]
          [ 4480 1600 ]
          [ 7680 2400 ]
        ];
      };
      focus = { lockin_delay = 500; };
      misc = { seq_inhibit = false; };
    };
  };
}
