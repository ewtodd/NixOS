{ inputs, ... }:
{
  imports = [
    ./packages/nixvim
    ./packages/kitty
  ];

  colorScheme = inputs.nix-colors.colorSchemes.dracula;
}
