{ ... }:
{
  imports = [ ./niri/niri-de.nix ];
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/e-play";
    logs.save = true;
  };
}
