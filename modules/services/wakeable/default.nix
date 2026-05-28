{
  config,
  lib,
  ...
}:
let
  cfg = config.systemOptions.services.wakeable;
in
{
  options.systemOptions.services.wakeable = {
    wiredInterface = lib.mkOption {
      type = lib.types.str;
      description = "Wired NIC name to arm for WoL (e.g. enp16s0).";
    };
    initrdNicModule = lib.mkOption {
      type = lib.types.str;
      description = "Kernel module name for the initrd to bring up the NIC (e.g. r8169, igc, e1000e).";
    };
    initrdSshPort = lib.mkOption {
      type = lib.types.port;
      default = 2223;
      description = "Port for the initrd dropbear sshd. Distinct from the real sshd port.";
    };
    initrdAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Pubkeys allowed to SSH into the initrd to unlock LUKS.";
    };
    initrdHostKeyPath = lib.mkOption {
      type = lib.types.path;
      default = "/etc/secrets/initrd/ssh_host_ed25519_key";
      description = ''
        Path on this host where the initrd ssh host key lives. Must exist at
        build time (NixOS reads it to bake into the initramfs). Generate once
        with: sudo ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    networking.interfaces.${cfg.wiredInterface}.wakeOnLan.enable = true;

    boot.initrd.systemd.enable = true;

    boot.initrd.availableKernelModules = [ cfg.initrdNicModule ];
    boot.initrd.kernelModules = [ cfg.initrdNicModule ];

    boot.initrd.systemd.network = {
      enable = true;
      networks."10-initrd-wired" = {
        matchConfig.Name = "en*";
        networkConfig.DHCP = "ipv4";
      };
    };

    boot.initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        port = cfg.initrdSshPort;
        authorizedKeys = cfg.initrdAuthorizedKeys;
        hostKeys = [ cfg.initrdHostKeyPath ];
      };
    };
  };
}
