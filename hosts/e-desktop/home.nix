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
      # Listens on all interfaces, but the host firewall admits only nu (Caddy,
      # birds.ethanwtodd.com with basic_auth); see configuration.nix.
      services.lifer = {
        enable = true;
        host = "0.0.0.0";
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
