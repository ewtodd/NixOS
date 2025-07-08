{ config, pkgs, inputs, system, ... }:
let
  bottles = pkgs.bottles.override { removeWarningPopup = true; };
  # fancy-cat = pkgs.callPackage (pkgs.fetchFromGitHub {
  #  owner = "freref";
  # repo = "fancy-cat-nix";
  #rev = "0c8e04a";
  # sha256 = "sha256-zem1jSbtQZNwE6wGE6fsG8/aHW/+brhh9f1QEtgk5oM=";
  # }) { };
in {

  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  environment.variables.EDITOR = "nvim";

  environment.shellAliases = {
    vim = "nvim";
    ":q" = "exit";
    nrs = "nh os switch /etc/nixos";
    fix-nixos-git =
      "sudo chown -R root:wheel /etc/nixos/* /etc/nixos/.* && sudo chmod -R g+rwx /etc/nixos/* /etc/nixos/.*";
  };
  environment.systemPackages = with pkgs; [
    git
    gh
    nh
    wget
    inkscape
    ipe
    firefox-wayland
    libreoffice
    tree
    zathura
    htop
    nix-prefetch-github
    nixfmt-classic
    tree
    usbutils
    pciutils
    unzip
    paprefs
    bottles
    zip
    gearlever
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    fira-code
    fira-code-symbols
  ];

}
