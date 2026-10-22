{
  "e-play" =
    {
      pkgs,
      inputs,
      system,
      ...
    }:
    {
      home.username = "e-play";
      home.homeDirectory = "/home/e-play";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/profiles/play.nix
        inputs.lifer.homeManagerModules.${system}.default
      ];
      # Local-only: the module's default host is 127.0.0.1, so nothing outside
      # this machine can reach the review app.
      services.lifer = {
        enable = true;
      };
      scheme = "${pkgs.base16-schemes}/share/themes/isotope.yaml";
    };
  "e-work" =
    { pkgs, ... }:
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
