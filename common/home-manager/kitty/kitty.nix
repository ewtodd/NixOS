{ config, lib, ... }:

with lib;

let
  colors = config.colorScheme.palette;
  opacity = "0.75";
in {
  config = mkIf config.programs.kitty.enable {
    programs.kitty = {
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
        background_opacity = "${opacity}";
        cursor_shape = "block";
        cursor_blink_interval = 0;
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
        notify_on_cmd_finish = "unfocused 1.0 notify";
        # Use nix-colors palette
        background = "#${colors.base00}";
        foreground = "#${colors.base05}";

        # Terminal colors using base16 standard
        color0 = "#${colors.base00}";
        color1 = "#${colors.base08}";
        color2 = "#${colors.base0B}";
        color3 = "#${colors.base0A}";
        color4 = "#${colors.base0D}";
        color5 = "#${colors.base0E}";
        color6 = "#${colors.base0C}";
        color7 = "#${colors.base05}";
        color8 = "#${colors.base03}";
        color9 = "#${colors.base08}";
        color10 = "#${colors.base0B}";
        color11 = "#${colors.base0A}";
        color12 = "#${colors.base0D}";
        color13 = "#${colors.base0E}";
        color14 = "#${colors.base0C}";
        color15 = "#${colors.base07}";

        selection_foreground = "#${colors.base00}";
        selection_background = "#${colors.base05}";
        url_color = "#${colors.base0D}";
        cursor = "#${colors.base05}";
        cursor_text_color = "#${colors.base00}";
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
  };
}
