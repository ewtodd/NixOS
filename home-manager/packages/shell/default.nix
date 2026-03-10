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
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
    }
    // lib.optionalAttrs (profile == "work" && isEOwner) {
      vpn = "sudo ${pkgs.openconnect}/bin/openconnect --protocol=anyconnect --authgroup=\"UMVPN-Only U-M Traffic alt\" umvpn.umnet.umich.edu";
    }
    // lib.optionalAttrs (isEOwner && isLaptop) {
      phone-home = "${pkgs.waypipe}/bin/waypipe ssh -p 2222 ${config.home.username}@ssh.ethanwtodd.com kitty";
      files-home = "${pkgs.sshfs}/bin/sshfs -p 2222 ${config.home.username}@ssh.ethanwtodd.com:/${config.home.homeDirectory} /${config.home.homeDirectory}/remoteHome";
    }
    // lib.optionalAttrs (isEOwner && isLaptop && profile == "work") {
      plots-home = "${pkgs.waypipe}/bin/waypipe --compress lz4 ssh -p 2222 e-work@ssh.ethanwtodd.com gthumb";
    };
  };

  home.activation.createDir = lib.mkIf (isEOwner && isLaptop) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/remoteHome
    ''
  );

  # to be removed once Thunderbird fixes itself
  home.activation.removeDir = lib.mkIf isEOwner (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -rf $HOME/Thunderbird
    ''
  );

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };
}
