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
    initExtra = lib.optionalString (isEOwner && !isLaptop) ''
      # Start xwayland-satellite for waypipe sessions so X11 apps (e.g. ROOT) work
      if [ -n "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]; then
        ${pkgs.xwayland-satellite}/bin/xwayland-satellite :1 > /dev/null 2>&1 &
        export DISPLAY=:1
      fi
    '';
    shellAliases = {
    }
    // lib.optionalAttrs (profile == "work" && isEOwner) {
      vpn = "sudo ${pkgs.openconnect}/bin/openconnect --protocol=anyconnect --authgroup=\"UMVPN-Only U-M Traffic alt\" umvpn.umnet.umich.edu";
    }
    // lib.optionalAttrs (isEOwner && isLaptop) {
      phone-home = "${pkgs.waypipe}/bin/waypipe --remote-node /dev/dri/igpu-render ssh e-desktop kitty";
      files-home = "${pkgs.sshfs}/bin/sshfs e-desktop:${config.home.homeDirectory} ${config.home.homeDirectory}/remoteHome";
    }
    // lib.optionalAttrs (isEOwner && isLaptop && profile == "work") {
      plots-home = "${pkgs.waypipe}/bin/waypipe --remote-node /dev/dri/igpu-render --compress lz4 ssh e-desktop gthumb";
    };
  };

  home.activation.createDir = lib.mkIf (isEOwner && isLaptop) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/remoteHome
    ''
  );

  home.activation.removeDir = lib.mkIf isEOwner (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -rf $HOME/Thunderbird
      rm -rf $HOME/thunderbird
    ''
  );

  programs.ssh = lib.mkIf isEOwner {
    enable = true;
    enableDefaultConfig = false;

    includes = lib.optionals (profile == "work") [ "/run/agenix/onyx-ssh-config" ];

    settings = {
      # The public-facing bastion. Connection multiplexing here so ProxyJump
      # / ProxyCommand into inner hosts reuses the same TCP+TLS to mu.
      bastion = {
        Hostname = "ssh.ethanwtodd.com";
        Port = 2222;
        User = "mu";
        ControlMaster = "auto";
        ControlPath = "${config.home.homeDirectory}/.ssh/sockets/%r@%h-%p";
        ControlPersist = "10m";
      };

      # The workstation behind the bastion. ProxyCommand runs the wake script
      # on mu first, so `ssh e-desktop` from anywhere transparently boots /
      # unlocks the box if it's cold.
      "e-desktop" = {
        Hostname = "10.0.0.4";
        User = config.home.username;
        ProxyCommand = "ssh bastion wake-and-relay-e-desktop";
      };

      # Admin shells on the infra hosts. No wake dance — these stay up.
      # Port 2222 is the inner sshd port (matches services.ssh.enable config);
      # without this, ProxyJump's %p defaults to 22 and the tunnel goes nowhere.
      "mu-admin" = {
        Hostname = "10.0.0.2";
        Port = 2222;
        User = "mu";
        ProxyJump = "bastion";
      };
      "nu-admin" = {
        Hostname = "10.0.0.7";
        Port = 2222;
        User = "nu";
        ProxyJump = "bastion";
      };
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };
}
