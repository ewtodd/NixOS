{
  config,
  lib,
  ...
}:
with lib;
{
  config = mkIf (config.systemOptions.security.harden.enable) {
    security = {
      protectKernelImage = true;
      sudo.enable = mkForce false;
      sudo-rs.enable = mkForce true;
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
      "firewire-core"
      "firewire_core"
      "firewire-ohci"
      "firewire_ohci"
      "firewire-sbp2"
      "firewire_sbp2"
      "vivid"
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
        wifi.macAddress = "stable-ssid";
      };

      firewall = {
        enable = true;
        allowedTCPPorts = [ 2222 ];
      };
    };

    boot.kernelParams = [
      "slab_nomerge"
      "vsyscall=none"
      "debugfs=off"
    ];

    boot.kernel.sysctl."kernel.kptr_restrict" = mkOverride 500 2;
    boot.kernel.sysctl."kernel.dmesg_restrict" = mkDefault true;
    boot.kernel.sysctl."kernel.unprivileged_bpf_disabled" = mkDefault true;
    boot.kernel.sysctl."kernel.yama.ptrace_scope" = mkDefault 2;
    boot.kernel.sysctl."kernel.ftrace_enabled" = mkDefault false;
    boot.kernel.sysctl."kernel.perf_event_paranoid" = mkDefault 3;

    boot.kernel.sysctl."net.core.bpf_jit_enable" = mkDefault false;

    boot.kernel.sysctl."net.ipv4.conf.all.log_martians" = mkDefault true;
    boot.kernel.sysctl."net.ipv4.conf.all.rp_filter" = mkDefault "1";
    boot.kernel.sysctl."net.ipv4.conf.default.log_martians" = mkDefault true;
    boot.kernel.sysctl."net.ipv4.conf.default.rp_filter" = mkDefault "1";

    boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = mkDefault true;

    boot.kernel.sysctl."net.ipv4.conf.all.accept_redirects" = mkDefault false;
    boot.kernel.sysctl."net.ipv4.conf.all.secure_redirects" = mkDefault false;
    boot.kernel.sysctl."net.ipv4.conf.default.accept_redirects" = mkDefault false;
    boot.kernel.sysctl."net.ipv4.conf.default.secure_redirects" = mkDefault false;
    boot.kernel.sysctl."net.ipv6.conf.all.accept_redirects" = mkDefault false;
    boot.kernel.sysctl."net.ipv6.conf.default.accept_redirects" = mkDefault false;

    boot.kernel.sysctl."net.ipv4.conf.all.send_redirects" = mkDefault false;
    boot.kernel.sysctl."net.ipv4.conf.default.send_redirects" = mkDefault false;
  };
}
