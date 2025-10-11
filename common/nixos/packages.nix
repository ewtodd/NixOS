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
      "sudo chmod 777 -R /etc/nixos && sudo chmod 777 -R /etc/nixos/.git && sudo chown $USER:users -R /etc/nixos && sudo chown $USER:users -R /etc/nixos/.git";
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
    openconnect
    tree
    usbutils
    pciutils
    unzip
    paprefs
    bottles
    wineWowPackages.stable
    winetricks
    zip
    gearlever
    imagemagick
    ghostscript
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.space-mono
    nerd-fonts.ubuntu
    fira-code
    fira-code-symbols
  ];

}
