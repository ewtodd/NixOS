{ pkgs, ... }:
{
  imports = [
    ./homebrew
    ./system-defaults
    ./lima-vms
  ];

  config = {
    nix.settings.experimental-features = "nix-command flakes";

    programs.zsh.enable = true;

    environment.variables.EDITOR = "nvim";

    environment.shellAliases = {
      vim = "nvim";
      ":q" = "exit";
      nrs = "nh darwin switch /etc/nixos";
      fix-nixos-git = "sudo chmod 777 -R /etc/nixos && sudo chmod 777 -R /etc/nixos/.git && sudo chown $USER:staff -R /etc/nixos && sudo chown $USER:staff -R /etc/nixos/.git";
      init-dev-env = "nix flake init -t github:ewtodd/dev-env --refresh";
      init-latex-env = "nix flake init -t github:ewtodd/latex-env --refresh";
      init-geant4-env = "nix flake init -t github:ewtodd/geant4-env --refresh";
      init-analysis-env = "nix flake init -t github:ewtodd/Analysis-Utilities --refresh";
      view-image = "kitten icat";
    };

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      claude-code
      git
      gh
      nh
      wget
      tree
      nixfmt-rfc-style
      usbutils
      poppler-utils
      pciutils
      unzip
      zip
      imagemagick
      ghostscript
    ];
  };
}
