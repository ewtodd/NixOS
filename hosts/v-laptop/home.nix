{
  "v-play" =
    { inputs, ... }:
    {
      home.username = "v-play";
      home.homeDirectory = "/home/v-play";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/common/profiles/play.nix
      ];
      colorScheme = inputs.nix-colors.colorSchemes.eris;
    };

  "v-work" =
    { pkgs, inputs, ... }:
    {
      home.username = "v-work";
      home.homeDirectory = "/home/v-work";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/common/profiles/work.nix
      ];
      home.packages = [ pkgs.signal-desktop ];
      colorScheme = inputs.nix-colors.colorSchemes.atelier-cave;
    };

  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "25.05";
      imports = [ ../../home-manager/root-user.nix ];
    };

}
