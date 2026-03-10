{
  "v-play" =
    { pkgs, ... }:
    let
      eris = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/tinted-theming/base16-schemes/refs/heads/main/eris.yaml";
        hash = "sha256-p3E5ksta+ruhiTYhqpwnC/92LBR5dZ+BSd+ozVPncw0=";
      };
    in
    {
      home.username = "v-play";
      home.homeDirectory = "/home/v-play";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/profiles/play.nix
      ];
      scheme = "${eris}";
    };

  "v-work" =
    { pkgs, ... }:
    {
      home.username = "v-work";
      home.homeDirectory = "/home/v-work";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/profiles/work.nix
      ];
      home.packages = [ pkgs.signal-desktop ];
      scheme = "${pkgs.base16-schemes}/share/themes/atelier-cave.yaml";
    };

  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "25.05";
      imports = [ ../../home-manager/profiles/root.nix ];
    };

}
