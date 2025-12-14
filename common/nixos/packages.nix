{ pkgs, ... }: {

  nixpkgs.config.allowUnfree = true;

  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  environment.variables.EDITOR = "nvim";

  environment.shellAliases = {
    vim = "nvim";
    ":q" = "exit";
    nrs = "nh os switch /etc/nixos";
    fix-nixos-git =
      "sudo chmod 777 -R /etc/nixos && sudo chmod 777 -R /etc/nixos/.git && sudo chown $USER:users -R /etc/nixos && sudo chown $USER:users -R /etc/nixos/.git";
    init-dev-env = "nix flake init -t github:ewtodd/dev-env --refresh";
    init-nm-env =
      "nix flake init -t github:ewtodd/Nuclear-Measurement-Toolkit --refresh";
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    nh
    wget
    inkscape
    firefox
    proton-pass
    libreoffice
    tree
    zathura
    htop
    nix-prefetch-github
    nixfmt-classic
    openconnect
    tree
    usbutils
    poppler-utils
    pciutils
    unzip
    paprefs
    wineWowPackages.stable
    winetricks
    zip
    gearlever
    imagemagick
    ghostscript
    spotify
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
