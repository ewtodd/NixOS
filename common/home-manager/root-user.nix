{ inputs, ... }:
{
  imports = [
    ./system-options.nix
    ./xdg/xdg.nix
    ./zathura/zathura.nix
    ./kitty/kitty.nix
    ./fastfetch/fastfetch.nix
    ./theming/theming.nix
    ./nixvim/nixvim.nix
  ];
  colorScheme = inputs.nix-colors.colorSchemes.dracula;
  programs.nixvim.enable = true;
  programs.kitty = {
    enable = true;
  };
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ls = "ls -vAF";
      ll = "ls -l";
    };
  };
  FontChoice = "JetBrains Mono Nerd Font";
}
