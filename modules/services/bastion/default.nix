{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.bastion;

  eDesktopIp = "10.0.0.4";
  eDesktopMac = "30:56:0f:4b:ac:de";
  innerSshPort = 2222;
  initrdSshPort = 2223;

  # Wake e-desktop and unlock it, with no relay attached. Both of its LUKS
  # volumes take a passphrase that exists only here, so this host is the only
  # thing on the network that can bring that machine up at all.
  wakeAndUnlock = pkgs.writeShellApplication {
    name = "wake-and-unlock-e-desktop";
    runtimeInputs = with pkgs; [
      wakeonlan
      netcat-openbsd
      openssh
      coreutils
    ];
    text = ''
      set -u

      EIP=${eDesktopIp}
      EMAC=${eDesktopMac}
      SSH_PORT=${toString innerSshPort}
      INITRD_PORT=${toString initrdSshPort}
      INITRD_KEY=${config.age.secrets.bastion-initrd-unlock-key.path}
      LUKS_PASS=${config.age.secrets.e-desktop-luks-passphrase.path}

      if nc -z -w 1 "$EIP" "$SSH_PORT" 2>/dev/null; then
        echo "e-desktop is already up" >&2
        exit 0
      fi

      echo "e-desktop not reachable, sending magic packet..." >&2
      wakeonlan "$EMAC" >&2 || true

      for _ in $(seq 1 90); do
        if nc -z -w 1 "$EIP" "$SSH_PORT" 2>/dev/null; then
          exit 0
        fi
        if nc -z -w 1 "$EIP" "$INITRD_PORT" 2>/dev/null; then
          echo "initrd ssh up, sending LUKS passphrase..." >&2
          ssh -i "$INITRD_KEY" \
              -o StrictHostKeyChecking=no \
              -o UserKnownHostsFile=/dev/null \
              -o LogLevel=ERROR \
              -p "$INITRD_PORT" \
              "root@$EIP" \
              'systemd-tty-ask-password-agent --query 2>/dev/null' \
              < "$LUKS_PASS" >&2 || true
          break
        fi
        sleep 1
      done

      for _ in $(seq 1 120); do
        if nc -z -w 1 "$EIP" "$SSH_PORT" 2>/dev/null; then
          exit 0
        fi
        sleep 1
      done

      echo "Timed out waiting for e-desktop sshd on $SSH_PORT" >&2
      exit 1
    '';
  };

  # ProxyCommand target for reaching e-desktop from outside: the same wake and
  # unlock, then hand over the socket. Everything it prints goes to stderr so
  # stdout stays clean for the ssh client on the far end.
  wakeAndRelay = pkgs.writeShellApplication {
    name = "wake-and-relay-e-desktop";
    runtimeInputs = [
      pkgs.netcat-openbsd
      wakeAndUnlock
    ];
    text = ''
      set -u

      EIP=${eDesktopIp}
      SSH_PORT=${toString innerSshPort}

      if ! nc -z -w 1 "$EIP" "$SSH_PORT" 2>/dev/null; then
        wake-and-unlock-e-desktop >&2 || exit 1
      fi

      exec nc "$EIP" "$SSH_PORT"
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    services.openssh.settings = {
      PasswordAuthentication = lib.mkForce false;
      KbdInteractiveAuthentication = lib.mkForce false;
      AuthenticationMethods = lib.mkForce "publickey";
      PermitRootLogin = "no";
      AllowAgentForwarding = "no";
      AllowTcpForwarding = "yes"; # required for ProxyJump from outside
      X11Forwarding = false;
      MaxAuthTries = 3;
      LoginGraceTime = "20s";
    };

    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        factor = "2";
        maxtime = "168h";
      };
    };

    # Export fail2ban ban counts to Prometheus (scraped by nu over the LAN; mu is
    # behind NAT with only :2222 forwarded, so :9191 is LAN-only regardless).
    services.prometheus.exporters.fail2ban = {
      enable = true;
      host = "0.0.0.0";
      openFirewall = true;
    };

    environment.systemPackages = [
      pkgs.wakeonlan
      wakeAndRelay
      wakeAndUnlock
    ];

    # The return half of e-desktop's scheduled poweroff. It shuts down on its
    # own timer; this brings it back a few minutes later, so the pair adds up
    # to an unattended reboot for a machine that cannot reboot unattended.
    #
    # Not Persistent: if this host was itself down at the scheduled minute,
    # waking e-desktop hours later serves nobody, and the next connection
    # through the relay wakes it anyway.
    systemd.services.wake-e-desktop = lib.mkIf (cfg.wakeCalendar != "") {
      description = "Wake and unlock e-desktop";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe wakeAndUnlock;
      };
    };

    systemd.timers.wake-e-desktop = lib.mkIf (cfg.wakeCalendar != "") {
      description = "Timer for waking e-desktop after its scheduled poweroff";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.wakeCalendar;
        Persistent = false;
        RandomizedDelaySec = "60";
      };
    };
  };
}
