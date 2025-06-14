{ config, pkgs, inputs, system, ... }: {

  imports = [ ../../nixvim/nixvim.nix ];

  environment.variables.EDITOR = "nvim";
  environment.shellAliases = { vim = "nvim"; };
  environment.systemPackages = with pkgs; [
    git
    gh
    firefox-wayland
    libreoffice
    geary
    tree
    fastfetch
    texliveSmall
    htop
    nix-prefetch-github
    nixfmt-classic
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    fira-code
    fira-code-symbols
  ];
}
