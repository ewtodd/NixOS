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
  isEDesktop = osConfig != null && osConfig.networking.hostName == "e-desktop";
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

      "e-desktop" = {
        Hostname = "10.0.0.4";
        User = config.home.username;
        ProxyCommand = "ssh bastion wake-and-relay-e-desktop";
      };

      "mu" = {
        Hostname = "10.0.0.2";
        Port = 2222;
        User = "mu";
        ProxyJump = "bastion";
      };
      "nu" = {
        Hostname = "10.0.0.7";
        Port = 2222;
        User = "nu";
        ProxyJump = "bastion";
      };
      "anton" = {
        Hostname = "10.0.0.3";
        Port = 2222;
        User = "anton";
        ProxyJump = "bastion";
      };
      "son-of-anton" = {
        Hostname = "10.0.0.5";
        Port = 2222;
        User = "son-of-anton";
        ProxyJump = "bastion";
      };
      # Colmena deploy targets: same inner hosts as the *-admin shells, as the key-only `deploy` user.
      # flake colmenaDeployments.*.targetHost points at these aliases -- closures push through the bastion,
      # working on- or off-LAN (split-horizon DNS resolves the bastion to its LAN address at home).
      "deploy-mu" = {
        Hostname = "10.0.0.2";
        Port = 2222;
        User = "deploy";
        ProxyJump = "bastion";
      };
      "deploy-nu" = {
        Hostname = "10.0.0.7";
        Port = 2222;
        User = "deploy";
        ProxyJump = "bastion";
      };
      "deploy-anton" = {
        Hostname = "10.0.0.3";
        Port = 2222;
        User = "deploy";
        ProxyJump = "bastion";
      };
      "deploy-son-of-anton" = {
        Hostname = "10.0.0.5";
        Port = 2222;
        User = "deploy";
        ProxyJump = "bastion";
      };
      "deploy-tony" = {
        Hostname = "10.0.0.8";
        Port = 2222;
        User = "deploy";
        ProxyJump = "bastion";
      };
      "tony" = {
        Hostname = "10.0.0.8";
        Port = 2222;
        User = "tony";
        ProxyJump = "bastion";
      };

      # Straight to the LAN address, for when nu is down: the aliases above reach their hosts through the
      # bastion's public name, which at home resolves (split-horizon) through nu's DNS.
      "mu-lan" = {
        Hostname = "10.0.0.2";
        Port = 2222;
        User = "mu";
      };
      "nu-lan" = {
        Hostname = "10.0.0.7";
        Port = 2222;
        User = "nu";
      };
      "anton-lan" = {
        Hostname = "10.0.0.3";
        Port = 2222;
        User = "anton";
      };
      "son-of-anton-lan" = {
        Hostname = "10.0.0.5";
        Port = 2222;
        User = "son-of-anton";
      };
      "tony-lan" = {
        Hostname = "10.0.0.8";
        Port = 2222;
        User = "tony";
      };
    }
    // lib.optionalAttrs isEDesktop {
      # nu over IPv6 link-local through this machine's wired port (enp14s0), for when the LAN has no IPv4
      # at all (nu's DHCP is down). `%%` is ssh_config's escape for the zone's `%`. nu-wan-ll is nu's WAN
      # port (the cloned BGW320 MAC): it answers here only if its cable has ended up on the LAN switch, as
      # after the 2026-10-13 RAM swap.
      "nu-ll" = {
        Hostname = "fe80::9e69:d3ff:fe3d:6780%%enp14s0";
        Port = 2222;
        User = "nu";
      };
      "nu-wan-ll" = {
        Hostname = "fe80::6e4b:b4ff:fe53:3ef0%%enp14s0";
        Port = 2222;
        User = "nu";
      };
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };
}
