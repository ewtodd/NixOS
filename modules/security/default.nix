{
  config,
  lib,
  pkgs,
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

    security.apparmor = {
      enable = true;
      packages = [ pkgs.apparmor-profiles ];
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

    boot.kernelParams = [
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc.shuffle=1"
      "pti=on"
      "randomize_kstack_offset=on"
      "vsyscall=none"
      "debugfs=off"
      "oops=panic"
      "lockdown=confidentiality"
    ];

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

    boot.kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "vm.unprivileged_userfaultfd" = 0;
      "kernel.kexec_load_disabled" = 1;
      "kernel.sysrq" = 4;

      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;

      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;

      "net.ipv4.conf.all.forwarding" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.forwarding" = 0;
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.default.accept_ra" = 0;

      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

      "fs.protected_symlinks" = 1;
      "fs.protected_hardlinks" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;

      "kernel.randomize_va_space" = 2;
      "kernel.exec-shield" = 1;

      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "cake";
    };

    systemd.coredump.enable = false;

    services = {
      logrotate.enable = true;
      geoclue2.enable = false;
      accounts-daemon.enable = false;
    };

    networking = {
      networkmanager = {
        enable = true;
        wifi.scanRandMacAddress = true;
        wifi.macAddress = "random";
        plugins = [ ];
      };

      firewall = {
        enable = true;
        allowedTCPPorts = [ 2222 ];
      };
    };
  };
}
