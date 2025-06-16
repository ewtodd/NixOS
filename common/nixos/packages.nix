{ config, pkgs, inputs, system, ... }:
let bottles = pkgs.bottles.override { removeWarningPopup = true; };
in {

  imports = [ ../../modules/nixvim/nixvim.nix ];

  environment.variables.EDITOR = "nvim";
  environment.shellAliases = { vim = "nvim"; };
  environment.systemPackages = with pkgs; [
    git
    gh
    wget
    firefox-wayland
    libreoffice
    geary
    tree
    fastfetch
    texliveSmall
    htop
    nix-prefetch-github
    nixfmt-classic
    tree
    usbutils
    unzip
    paprefs
    bottles
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    fira-code
    fira-code-symbols
  ];
}
