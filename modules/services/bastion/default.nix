{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.bastion;

  eWorkstationIp = "10.0.0.4";
  eWorkstationMac = "30:56:0f:4b:ac:de";
  innerSshPort = 2222;
  initrdSshPort = 2223;

  # Public half of e-workstation's /etc/secrets/initrd/ssh_host_ed25519_key
  # (systemOptions.services.wakeable.initrdHostKeyPath). Regenerating that key
  # means replacing this line, or the unlock refuses to send the passphrase.
  initrdKnownHosts = pkgs.writeText "e-workstation-initrd-known-hosts" ''
    e-workstation-initrd ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUVx2UU/jPxlelg7k94CVl6Cq7VJjB3RW+pJpZtm3CX
  '';

  # Wake e-workstation and unlock it, with no relay attached. Both of its LUKS
  # volumes take a passphrase that exists only here, so this host is the only
  # thing on the network that can bring that machine up at all.
  wakeAndUnlock = pkgs.writeShellApplication {
    name = "wake-and-unlock-e-workstation";
    runtimeInputs = with pkgs; [
      wakeonlan
      netcat-openbsd
      openssh
      coreutils
    ];
    text = ''
      set -u

      EIP=${eWorkstationIp}
      EMAC=${eWorkstationMac}
      SSH_PORT=${toString innerSshPort}
      INITRD_PORT=${toString initrdSshPort}
      INITRD_KEY=${config.age.secrets.bastion-initrd-unlock-key.path}
      LUKS_PASS=${config.age.secrets.e-workstation-luks-passphrase.path}

      if nc -z -w 1 "$EIP" "$SSH_PORT" 2>/dev/null; then
        echo "e-workstation is already up" >&2
        exit 0
      fi

      echo "e-workstation not reachable, sending magic packet..." >&2
      wakeonlan "$EMAC" >&2 || true

      for _ in $(seq 1 90); do
        if nc -z -w 1 "$EIP" "$SSH_PORT" 2>/dev/null; then
          exit 0
        fi
        if nc -z -w 1 "$EIP" "$INITRD_PORT" 2>/dev/null; then
          echo "initrd ssh up, sending LUKS passphrase..." >&2
          ssh -i "$INITRD_KEY" \
              -o StrictHostKeyChecking=yes \
              -o HostKeyAlias=e-workstation-initrd \
              -o UserKnownHostsFile=${initrdKnownHosts} \
              -o GlobalKnownHostsFile=/dev/null \
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

      echo "Timed out waiting for e-workstation sshd on $SSH_PORT" >&2
      exit 1
    '';
  };

  # ProxyCommand target for reaching e-workstation from outside: the same wake and
  # unlock, then hand over the socket. Everything it prints goes to stderr so
  # stdout stays clean for the ssh client on the far end.
  wakeAndRelay = pkgs.writeShellApplication {
    name = "wake-and-relay-e-workstation";
    runtimeInputs = [
      pkgs.netcat-openbsd
      wakeAndUnlock
    ];
    text = ''
      set -u

      EIP=${eWorkstationIp}
      SSH_PORT=${toString innerSshPort}

      if ! nc -z -w 1 "$EIP" "$SSH_PORT" 2>/dev/null; then
        wake-and-unlock-e-workstation >&2 || exit 1
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
    # The return half of e-workstation's scheduled poweroff: it shuts down on its own timer, this wakes it a few
    # minutes later -- together an unattended reboot for a machine that cannot reboot unattended.
    # Not Persistent: waking e-workstation hours late serves nobody, and the next relay connection wakes it anyway.
    systemd.services.wake-e-workstation = lib.mkIf (cfg.wakeCalendar != "") {
      description = "Wake and unlock e-workstation";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe wakeAndUnlock;
      };
    };

    systemd.timers.wake-e-workstation = lib.mkIf (cfg.wakeCalendar != "") {
      description = "Timer for waking e-workstation after its scheduled poweroff";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.wakeCalendar;
        Persistent = false;
        RandomizedDelaySec = "60";
      };
    };
  };
}
