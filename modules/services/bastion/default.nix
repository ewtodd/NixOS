{
  config,
  lib,
  pkgs,
  ...
}:
let
  eDesktopIp = "10.0.0.4";
  eDesktopMac = "30:56:0f:4b:ac:de";
  innerSshPort = 2222;
  initrdSshPort = 2223;

  wakeAndRelay = pkgs.writeShellApplication {
    name = "wake-and-relay-e-desktop";
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
        exec nc "$EIP" "$SSH_PORT"
      fi

      echo "e-desktop not reachable, sending magic packet..." >&2
      wakeonlan "$EMAC" >&2 || true

      for _ in $(seq 1 90); do
        if nc -z -w 1 "$EIP" "$SSH_PORT" 2>/dev/null; then
          break
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
          exec nc "$EIP" "$SSH_PORT"
        fi
        sleep 1
      done

      echo "Timed out waiting for e-desktop sshd on $SSH_PORT" >&2
      exit 1
    '';
  };
in
{
  config = lib.mkIf config.systemOptions.services.bastion.enable {
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
      listenAddress = "0.0.0.0";
      openFirewall = true;
    };

    environment.systemPackages = [
      pkgs.wakeonlan
      wakeAndRelay
    ];
  };
}
