{
  pkgs,
  lib,
  config,
  osConfig ? null,
  ...
}:
let
  profile = config.Profile;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;

  # Safely access osConfig if available
  isEOwner = if osConfig != null then osConfig.systemOptions.owner.e.enable else false;
  isLaptop = if osConfig != null then osConfig.systemOptions.deviceType.laptop.enable else false;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "ls -l";
      vim = "nvim";
      ":q" = "exit";

      # Platform-specific nrs alias
      nrs = if isLinux then "nh os switch /etc/nixos" else "nh darwin switch /etc/nixos";

      # Platform-specific git fix alias
      fix-nixos-git = if isLinux
        then "sudo chmod 777 -R /etc/nixos && sudo chmod 777 -R /etc/nixos/.git && sudo chown $USER:users -R /etc/nixos && sudo chown $USER:users -R /etc/nixos/.git"
        else "sudo chmod 777 -R /etc/nixos && sudo chmod 777 -R /etc/nixos/.git && sudo chown $USER:staff -R /etc/nixos && sudo chown $USER:staff -R /etc/nixos/.git";

      init-dev-env = "nix flake init -t github:ewtodd/dev-env --refresh";
      init-latex-env = "nix flake init -t github:ewtodd/latex-env --refresh";
      init-geant4-env = "nix flake init -t github:ewtodd/geant4-env --refresh";
      init-analysis-env = "nix flake init -t github:ewtodd/Analysis-Utilities --refresh";
      view-image = "kitten icat";
    } // lib.optionalAttrs (profile == "work" && isEOwner && isLinux) {
      vpn = "sudo ${pkgs.openconnect}/bin/openconnect --protocol=anyconnect --authgroup=\"UMVPN-Only U-M Traffic alt\" umvpn.umnet.umich.edu";
    } // lib.optionalAttrs (isEOwner && isLaptop && isLinux) {
      phone-home = "ssh ${config.home.username}@ssh.ethanwtodd.com -p 2222";
      files-home = "sftp -P 2222 ${config.home.username}@ssh.ethanwtodd.com";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
