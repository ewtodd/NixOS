{ inputs, pkgs, ... }:

{
  programs.hyprlock = {
    enable = true;
    package = inputs.hyprlock-greetd.packages."${pkgs.system}".hyprlock;
  };
}
