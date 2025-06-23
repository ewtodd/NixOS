{ pkgs, ... }: {
  programs.swaylock = {

    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      screenshots = true;
      effect-blur = "7x7";
      indicator = true;
      clock = true;
      timestr = "%-I:%M %p";
      datestr = "%a, %b %d";
      color = "cba6f7";
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      show-failed-attempts = true;
      daemonize = true;
      fade = 0.5;
      text-color = "#3e8fb0";
      text-clear-color = "#9ccfd8";
      text-caps-lock-color = "#f6c177";
      text-ver-color = "#c4a7e7";
      text-wrong-color = "#eb6f92";

      bs-hl-color = "#23213666";
      key-hl-color = "#3e8fb0";
      caps-lock-bs-hl-color = "#23213666";
      caps-lock-key-hl-color = "#f6c177";

      separator-color = "#00000000";

      inside-color = "#3e8fb055";
      inside-clear-color = "#9ccfd855";
      inside-caps-lock-color = "#f6c17755";
      inside-ver-color = "#c4a7e755";
      inside-wrong-color = "#eb6f9255";

      line-color = "#3e8fb011";
      line-clear-color = "#9ccfd811";
      line-caps-lock-color = "#f6c17711";
      line-ver-color = "#c4a7e711";
      line-wrong-color = "#eb6f9211";

      ring-color = "#3e8fb0aa";
      ring-clear-color = "#9ccfd8aa";
      ring-caps-lock-color = "#f6c177aa";
      ring-ver-color = "#c4a7e7aa";
      ring-wrong-color = "#eb6f92aa";
    };
  };
}
