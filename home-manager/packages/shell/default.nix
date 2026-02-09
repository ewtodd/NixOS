{
  pkgs,
  lib,
  config,
  osConfig ? null,
  ...
}:
let
  profile = config.Profile;

  isEOwner = if osConfig != null then osConfig.systemOptions.owner.e.enable else false;
  isLaptop = if osConfig != null then osConfig.systemOptions.deviceType.laptop.enable else false;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
    }
    // lib.optionalAttrs (profile == "work" && isEOwner) {
      vpn = "sudo ${pkgs.openconnect}/bin/openconnect --protocol=anyconnect --authgroup=\"UMVPN-Only U-M Traffic alt\" umvpn.umnet.umich.edu";
    }
    // lib.optionalAttrs (isEOwner && isLaptop) {
      phone-home = "ssh ${config.home.username}@ssh.ethanwtodd.com -p 2222";
      files-home = "sftp -P 2222 ${config.home.username}@ssh.ethanwtodd.com";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
