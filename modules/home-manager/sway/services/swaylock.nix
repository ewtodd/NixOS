{ pkgs, ... }: {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;

    settings = {
      screenshots = true;
      effect-blur = "7x7";

      effect-compose =
        "50%,77%;center;/etc/nixos/modules/home-manager/sway/services/nixos_dracula.png";

      # Hide indicator until typing begins
      indicator-idle-visible = false; # This hides the indicator when idle
      indicator-y-position = "300";
      # Clock configuration - will be visible when indicator is hidden
      clock = true;
      timestr = "%-I:%M %p";
      datestr = "%a, %b %d";
      font = "JetBrainsMonoNF";
      font-size = 32;

      indicator-radius = 150;
      show-failed-attempts = true;
      ignore-empty-password = true;
      daemonize = true;
      fade = 5;
      grace = 5;

      # Dracula Color Scheme
      color = "282a36";

      # Text colors
      text-color = "#f8f8f2";
      text-clear-color = "#50fa7b";
      text-caps-lock-color = "#ffb86c";
      text-ver-color = "#bd93f9";
      text-wrong-color = "#ff5555";

      # Other colors...
      bs-hl-color = "#44475a66";
      key-hl-color = "#8be9fd";
      caps-lock-bs-hl-color = "#44475a66";
      caps-lock-key-hl-color = "#ffb86c";
      separator-color = "#6272a4";

      inside-color = "#282a3655";
      inside-clear-color = "#50fa7b55";
      inside-caps-lock-color = "#ffb86c55";
      inside-ver-color = "#bd93f955";
      inside-wrong-color = "#ff555555";

      line-color = "#44475a";
      line-clear-color = "#50fa7b";
      line-caps-lock-color = "#ffb86c";
      line-ver-color = "#bd93f9";
      line-wrong-color = "#ff5555";

      ring-color = "#6272a4aa";
      ring-clear-color = "#50fa7baa";
      ring-caps-lock-color = "#ffb86caa";
      ring-ver-color = "#bd93f9aa";
      ring-wrong-color = "#ff5555aa";
    };
  };
}
