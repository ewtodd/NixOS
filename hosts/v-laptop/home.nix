{
  "v-play" =
    { inputs, pkgs, ... }:
    {
      home.username = "v-play";
      home.homeDirectory = "/home/v-play";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/profiles/play.nix
      ];
      scheme = "${pkgs.base16-schemes}/share/themes/eris.yaml";
    };

  "v-work" =
    { pkgs, inputs, ... }:
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
