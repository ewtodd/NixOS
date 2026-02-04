{ inputs, ... }:
{
  imports = [
    ../packages
    ../system-options
    ../../darwin
  ];

  Profile = "root";
  colorScheme = inputs.nix-colors.colorSchemes.dracula;
}
