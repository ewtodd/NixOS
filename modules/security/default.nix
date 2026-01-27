{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.systemOptions.security.harden.enable) {
    security = {
      protectKernelImage = true;
      lockKernelModules = true;

      sudo.enable = lib.mkForce false;
      sudo-rs.enable = lib.mkForce true;
    };

    security.pam.loginLimits = [
      {
        domain = "*";
        type = "hard";
        item = "core";
        value = "0";
      }
    ];

    services.timesyncd = {
      enable = true;
      servers = [
        "0.nixos.pool.ntp.org"
        "1.nixos.pool.ntp.org"
        "2.nixos.pool.ntp.org"
        "3.nixos.pool.ntp.org"
      ];
    };

    boot.blacklistedKernelModules = [
      "dccp"
      "sctp"
      "rds"
      "tipc"
      "n-hdlc"
      "ax25"
      "netrom"
      "x25"
      "rose"
      "decnet"
      "econet"
      "af_802154"
      "ipx"
      "appletalk"
      "psnap"
      "p8023"
      "p8022"
      "can"
      "atm"
      "cramfs"
      "freevxfs"
      "jffs2"
      "hfs"
      "hfsplus"
      "udf"
    ];

    systemd.coredump.enable = false;

    services = {
      logrotate.enable = true;
      geoclue2.enable = false;
      accounts-daemon.enable = false;
    };

    networking = {
      networkmanager = {
        enable = true;
        wifi.macAddress = "random";
      };

      firewall = {
        enable = true;
        allowedTCPPorts = [ 2222 ];
      };
    };
  };
}
