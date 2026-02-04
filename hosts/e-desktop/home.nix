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
  "e-work" =
    { inputs, ... }:
    {
      home.username = "e-work";
      home.homeDirectory = "/home/e-work";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/common/profiles/work.nix
      ];
      colorScheme = inputs.nix-colors.colorSchemes.kanagawa;
    };
  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "25.05";
      imports = [ ../../home-manager/common/profiles/root.nix ];
    };
}
