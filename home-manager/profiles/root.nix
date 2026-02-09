{ inputs, ... }:
{
  imports = [
    ../default.nix
  ];

  Profile = "root";
  colorScheme = inputs.nix-colors.colorSchemes.dracula;
}
