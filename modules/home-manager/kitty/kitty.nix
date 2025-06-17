{config, pkgs, ...}: {
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
      background_opacity = "0.65";
      background = "#1a1625";
      foreground = "#e8d5ff";
      color0 = "#2d1b3d";
      color1 = "#ff6b9d";
      color2 = "#7dd3fc";
      color3 = "#fbbf24";
      color4 = "#8b5cf6";
      color5 = "#ec4899";
      color6 = "#06b6d4";
      color7 = "#f1e6ff";
      color8 = "#4c3957";
      color9 = "#ff8fab";
      color10 = "#87ceeb";
      color11 = "#fde047";
      color12 = "#a78bfa";
      color13 = "#f472b6";
      color14 = "#22d3ee";
      color15 = "#ffffff";
      selection_foreground = "#1a1625";
      selection_background = "#c084fc";
      url_color = "#8b5cf6";
      cursor = "#ff6b9d";
      cursor_text_color = "#1a1625";
      cursor_shape = "block";
      cursor_blink_interval = 0;
      active_tab_foreground = "#1a1625";
      active_tab_background = "#c084fc";
      inactive_tab_foreground = "#9ca3af";
      inactive_tab_background = "#374151";
      active_border_color = "#8b5cf6";
      inactive_border_color = "#4c3957";
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
