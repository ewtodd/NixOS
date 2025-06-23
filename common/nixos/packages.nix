{ config, pkgs, inputs, system, ... }:
let
  bottles = pkgs.bottles.override { removeWarningPopup = true; };
  fancy-cat = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "freref";
    repo = "fancy-cat-nix";
    rev = "0c8e04a";
    sha256 = "sha256-zem1jSbtQZNwE6wGE6fsG8/aHW/+brhh9f1QEtgk5oM=";
  }) { };
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
    tree
    fancy-cat
    texliveSmall
    htop
    nix-prefetch-github
    nixfmt-classic
    tree
    usbutils
    pciutils
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
