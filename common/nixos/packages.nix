{ pkgs, ... }:
let bottles = pkgs.bottles.override { removeWarningPopup = true; };

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
