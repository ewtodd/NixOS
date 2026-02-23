{
  config,
  osConfig,
  ...
}:
let
  colors = config.colorScheme.palette;
  opacity = if (osConfig.systemOptions.owner.e.enable) then "0.9" else "0.925";
in
{
  programs.kitty = {
    enable = true;
    font = {
      name = "Ubuntu Nerd Font";
      size = 13.0;
    };

    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      remember_window_size = "no";
      background_opacity = "${opacity}";
      cursor_shape = "block";
      cursor_blink_interval = 0;
      copy_on_select = "yes";
      strip_trailing_spaces = "smart";
      enable_audio_bell = "no";
      visual_bell_duration = 0.0;
      window_padding_width = 4;
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      sync_to_monitor = "yes";
      confirm_os_window_close = "-1";
      notify_on_cmd_finish = "unfocused 90.0 notify";
      hide_window_decorations = "no";
      background_blur = 1;

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
    '';
  };
}
