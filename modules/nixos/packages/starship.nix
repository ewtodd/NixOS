{ pkgs, ... }: {

  programs.starship = {
    enable = true;
    settings = { cmd_duration = { show_notifications = false; }; };
  };
  programs.bash = {
    shellInit = "eval $(${pkgs.starship}/bin/starship init bash)";
  };
}
