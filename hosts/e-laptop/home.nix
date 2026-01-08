{
  "e-play" =
    { inputs, ... }:
    {
      home.username = "e-play";
      home.homeDirectory = "/home/e-play";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/play-user.nix
      ];
      colorScheme = inputs.nix-colors.colorSchemes.catppuccin-frappe;
    };
  "e-work" =
    { inputs, ... }:
    {
      home.username = "e-work";
      home.homeDirectory = "/home/e-work";
      home.stateVersion = "25.05";
      imports = [
        ../../home-manager/work-user.nix
      ];
      programs.bash.shellAliases = {
      };
      colorScheme = inputs.nix-colors.colorSchemes.kanagawa;
    };
  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "25.05";
      imports = [ ../../home-manager/root-user.nix ];
    };
}
