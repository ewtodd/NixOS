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

      "fs.protected_symlinks" = 1;
      "fs.protected_hardlinks" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;

      "kernel.randomize_va_space" = 2;
      "kernel.exec-shield" = 1;
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
        wifi.macAddress = "random";
      };

      firewall = {
        enable = true;
        allowedTCPPorts = [ 2222 ];
      };
    };
  };
}
