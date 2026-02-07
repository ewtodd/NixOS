{ pkgs, ... }:
{
  imports = [
    ./homebrew
    ./system-defaults
  ];

  config = {
    nix.settings.experimental-features = "nix-command flakes";

    programs.zsh.enable = true;

    environment.variables.EDITOR = "nvim";

    users.groups = {
      nixconfig = { };
    };

    environment.shellAliases = {
      vim = "nvim";
      ":q" = "exit";
      fix-nixos-git = "sudo chown -R root:nixconfig /etc/nixos && sudo chmod -R 2775 /etc/nixos && git config --global --add safe.directory /etc/nixos && git -C /etc/nixos config core.fileMode false";
      nrs = "sudo darwin-rebuild switch --flake /etc/nixos";
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
