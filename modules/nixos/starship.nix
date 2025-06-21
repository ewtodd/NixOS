{ ... }: {
  programs.starship = { enable = true; };
  programs.bash = { shellInit = "eval $(starship init bash)"; };
}
