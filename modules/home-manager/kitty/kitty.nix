{ config, pkgs, ... }: {
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrains Mono Nerd Font";
      size = 13.0;
    };
    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      initial_window_width = 700;
      initial_window_height = 500;
      remember_window_size = "no";
      background_opacity = "0.75";

      # Dracula theme colors
      background = "#282a36";
      foreground = "#f8f8f2";

      # Black
      color0 = "#21222c";
      color8 = "#6272a4";

      # Red
      color1 = "#ff5555";
      color9 = "#ff6e6e";

      # Green
      color2 = "#50fa7b";
      color10 = "#69ff94";

      # Yellow
      color3 = "#f1fa8c";
      color11 = "#ffffa5";

      # Blue
      color4 = "#bd93f9";
      color12 = "#d6acff";

      # Magenta
      color5 = "#ff79c6";
      color13 = "#ff92df";

      # Cyan
      color6 = "#8be9fd";
      color14 = "#a4ffff";

      # White
      color7 = "#f8f8f2";
      color15 = "#ffffff";

      selection_foreground = "#282a36";
      selection_background = "#44475a";
      url_color = "#8be9fd";
      cursor = "#f8f8f2";
      cursor_text_color = "#282a36";
      cursor_shape = "block";
      cursor_blink_interval = 0;

      active_tab_foreground = "#282a36";
      active_tab_background = "#f8f8f2";
      inactive_tab_foreground = "#6272a4";
      inactive_tab_background = "#21222c";

      active_border_color = "#ff79c6";
      inactive_border_color = "#44475a";

      scrollback_lines = 1000;
      copy_on_select = "yes";
      strip_trailing_spaces = "smart";
      enable_audio_bell = "no";
      visual_bell_duration = 0.0;
      hide_window_decorations = "no";
      window_padding_width = 4;
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/mykitty";
      repaint_delay = 2;
      input_delay = 1;
      sync_to_monitor = "yes";
      confirm_os_window_close = "-1";
    };

    extraConfig = ''
      # Key bindings
      map ctrl+shift+c copy_to_clipboard
      map ctrl+shift+v paste_from_clipboard
      map shift+insert paste_from_selection
      map ctrl+shift+r show_scrollback
      map ctrl+shift+u show_unicode_input
      map ctrl+shift+n new_window
      map ctrl+plus change_font_size all +1.0
      map ctrl+equal change_font_size all +1.0
      map ctrl+kp_add change_font_size all +1.0
      map ctrl+minus change_font_size all -1.0
      map ctrl+kp_subtract change_font_size all -1.0
      map ctrl+0 change_font_size all 0
      map ctrl+shift+enter new_window_with_cwd
      map ctrl+shift+t new_tab_with_cwd
      map ctrl+h neighboring_window left
      map ctrl+j neighboring_window down
      map ctrl+k neighboring_window up
      map ctrl+l neighboring_window right
    '';
  };
}
