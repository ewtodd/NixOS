{ pkgs, ... }: {
  programs.starship = { enable = true; };
  programs.bash = {
    shellInit = "eval $(${pkgs.starship}/bin/starship init bash)";
  };
}
