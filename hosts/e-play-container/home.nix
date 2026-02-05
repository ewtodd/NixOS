{
  "e-play" =
    { inputs, ... }:
    {
      home.username = "e-play";
      home.homeDirectory = "/home/e-play";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/common/profiles/play.nix
      ];
      colorScheme = inputs.nix-colors.colorSchemes.harmonic16-dark;
    };
  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "25.05";
      imports = [ ../../home-manager/common/profiles/root.nix ];
    };
}
