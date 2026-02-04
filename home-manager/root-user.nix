{ inputs, ... }:
{
  imports = [
    ./common/packages/nixvim
    ./common/packages/kitty
  ];

  colorScheme = inputs.nix-colors.colorSchemes.dracula;
}
