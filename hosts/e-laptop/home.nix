{
  "e-play" =
    { inputs, pkgs, ... }:
    {
      home.username = "e-play";
      home.homeDirectory = "/home/e-play";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/profiles/play.nix
      ];
      scheme = "${pkgs.base16-schemes}/share/themes/harmonic16-dark.yaml";
    };
  "e-work" =
    { inputs, pkgs, ... }:
    {
      home.username = "e-work";
      home.homeDirectory = "/home/e-work";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/profiles/work.nix
      ];
      scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    };
  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "25.05";
      imports = [ ../../home-manager/profiles/root.nix ];
    };
}
