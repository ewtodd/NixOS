{
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
