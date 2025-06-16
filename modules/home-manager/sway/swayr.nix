{ config, pkgs, ... }: {
  programs.swayr = {
    enable = true;
    settings = {
      menu = {
        executable = "${pkgs.fuzzel}/bin/fuzzel";
        args = [
          "--show=dmenu"
          "--allow-markup"
          "--allow-images"
          "--insensitive"
          "--cache-file=/dev/null"
          "--parse-search"
          "--height=40%"
          "--prompt={prompt}"
        ];
      };

      format = {
        output_format = "{indent}Output {name}    ({id})";
        workspace_format =
          "{indent}Workspace {name} [{layout}] on output {output_name}    ({id})";
        container_format =
          "{indent}Container [{layout}] {marks} on workspace {workspace_name}    ({id})";
        window_format =
          "img:{app_icon}:text:{indent}{app_name} — {urgency_start}“{title}”{urgency_end} {marks} on workspace {workspace_name} / {output_name}    ({id})";
        indent = "    ";
        urgency_start = "";
        urgency_end = "";
        html_escape = true;
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

      focus = { lockin_delay = 750; };

      misc = { seq_inhibit = false; };
    };
  };

}
