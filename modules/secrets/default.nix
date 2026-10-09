{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.agenix.nixosModules.default ];

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ]
  ++ lib.optional config.systemOptions.owner.e.enable "/home/e-work/.ssh/id_ed25519"
  ++ lib.optionals config.systemOptions.owner.v.enable [
    "/home/v-work/.ssh/id_ed25519"
    "/home/v-play/.ssh/id_ed25519"
  ];

  age.secrets = lib.mkMerge [
    (lib.mkIf config.systemOptions.owner.e.enable {
      onyx-ssh-config = {
        file = ../../secrets/onyx-ssh-config.age;
        owner = "e-work";
        mode = "0400";
      };
    })
    (lib.mkIf config.systemOptions.services.backup.client.enable {
      # Borg passphrase; client-side encryption, so the server stores ciphertext.
      borg-passphrase = {
        file = ../../secrets/borg-passphrase.age;
        mode = "0400";
      };
    })
    (lib.mkIf config.systemOptions.services.dyndns.enable {
      namecheap-ddns = {
        file = ../../secrets/namecheap-ddns.age;
        mode = "0400";
      };
    })
    (lib.mkIf config.systemOptions.services.bastion.enable {
      # owner=mu because the wake-and-relay script runs as user `mu` (invoked
      # via ssh ProxyCommand by clients), so it needs read access to these.
      e-desktop-luks-passphrase = {
        file = ../../secrets/e-desktop-luks-passphrase.age;
        owner = "mu";
        mode = "0400";
      };
      bastion-initrd-unlock-key = {
        file = ../../secrets/bastion-initrd-unlock-key.age;
        owner = "mu";
        mode = "0400";
      };
    })
    (lib.mkIf config.systemOptions.services.nextcloud.enable {
      nextcloud-admin-password = {
        file = ../../secrets/nextcloud-admin-password.age;
        mode = "0400";
      };
    })
    (lib.mkIf config.systemOptions.services.grafana.enable {
      # Read at startup by the grafana service (runs as the grafana user).
      grafana-admin-password = {
        file = ../../secrets/grafana-admin-password.age;
        owner = "grafana";
        mode = "0400";
      };
      grafana-secret-key = {
        file = ../../secrets/grafana-secret-key.age;
        owner = "grafana";
        mode = "0400";
      };
    })
    (lib.mkIf config.systemOptions.services.searxng.enable {
      # Read by the searx service (runs as user `searx`) as an EnvironmentFile;
      # provides $SEARX_SECRET_KEY referenced from settings.server.secret_key.
      searxng-secret-key = {
        file = ../../secrets/searxng-secret-key.age;
        owner = "searx";
        mode = "0400";
      };
    })
    (lib.mkIf config.systemOptions.services.signal-cli.enable {
      # signal-cli reads SIGNAL_PHONE (the bot's number) from this file.
      # Runs as user `signal-cli`.
      signal-cli-env = {
        file = ../../secrets/signal-cli-env.age;
        owner = "signal-cli";
        group = "signal-cli";
        mode = "0440";
      };
    })
    (lib.mkIf config.systemOptions.services.bifrost.enable {
      # Bifrost server env (file content: BIFROST_SPIKE_VK=..., admin
      # username/password, BIFROST_ENCRYPTION_KEY=..., DEEPSEEK_API_KEY=...).
      # Read by the bifrost systemd service as its EnvironmentFile.
      bifrost-env = {
        file = ../../secrets/bifrost-env.age;
        mode = "0400";
      };
      # Per-consumer Bifrost virtual keys (BIFROST_OPENCODE_VK,
      # BIFROST_OPENWEBUI_VK, BIFROST_SOA_VK, BIFROST_FRIEND_VK). Read by the
      # bifrost service (root) and by the open-webui wrapper (group).
      bifrost-keys = {
        file = ../../secrets/bifrost-keys.age;
        group = "open-webui";
        mode = "0440";
      };
    })
    # Gateway env (SIGNAL_ACCOUNT=..., optional DISCORD/SLACK tokens). One file, read by every instance --
    # they share a Signal account. 0440 group-readable by 'son-of-anton' (instances are separate users);
    # never 0444: the group is the boundary.
    (lib.mkIf config.systemOptions.services.son-of-anton.enable {
      son-of-anton-env = {
        file = ../../secrets/son-of-anton-env.age;
        group = "son-of-anton";
        mode = "0440";
      };
      # Per-instance routing: every service sees every Signal event; SIGNAL_GROUP_ALLOWED_USERS decides which
      # instance answers. Encrypted because the repo is public and a group id names a real chat.
      # Appended AFTER son-of-anton-env, so a re-declared key here wins.
      son-of-anton-work-env = {
        file = ../../secrets/son-of-anton-work-env.age;
        group = "son-of-anton";
        mode = "0440";
      };
      son-of-anton-play-env = {
        file = ../../secrets/son-of-anton-play-env.age;
        group = "son-of-anton";
        mode = "0440";
      };
      # Also re-declares SIGNAL_ALLOWED_USERS with the household members. The
      # shared secret keeps the single-owner allowlist, so widening it here
      # cannot widen work or play.
      son-of-anton-house-env = {
        file = ../../secrets/son-of-anton-house-env.age;
        group = "son-of-anton";
        mode = "0440";
      };
      # The two project instances, one friend each. Same shape as house: own group id plus a
      # SIGNAL_ALLOWED_USERS of owner + that one friend, scoped by file order -- no friend is ever authorized
      # on work, play, house, or each other's instance.
      son-of-anton-ricky-env = {
        file = ../../secrets/son-of-anton-ricky-env.age;
        group = "son-of-anton";
        mode = "0440";
      };
      # GitHub SSH *private* deploy key for the ricky instance (the public
      # half goes on GitHub). Encrypted because the repo is public; recipients
      # mirror the instance envs: the human devices plus the server that must
      # decrypt it. The son-of-anton module installs it and a routing ssh
      # config into ricky HOME (git.github) so the agent can clone and push.
      soa-ricky-github-key = {
        file = ../../secrets/soa-ricky-github-key.age;
        owner = "soa-ricky";
        mode = "0400";
      };
      # Also carries DATABENTO_API_KEY for the Trump project (its flake's
      # shellHook expects it in the environment, and the key is rotated).
      son-of-anton-markets-env = {
        file = ../../secrets/son-of-anton-markets-env.age;
        group = "son-of-anton";
        mode = "0440";
      };
    })
    (lib.mkIf config.systemOptions.owner.e.enable {
      # Per-consumer Bifrost keys; opencode and the son-of-anton instances
      # source this for BIFROST_OPENCODE_VK / BIFROST_SOA_VK.
      bifrost-keys = {
        file = ../../secrets/bifrost-keys.age;
        group = "users";
        mode = "0440";
      };
    })
    (lib.mkIf config.systemOptions.owner.v.enable {
      # The son-of-anton home module sources this for BIFROST_SOA_VK.
      bifrost-keys = {
        file = ../../secrets/bifrost-keys.age;
        group = "users";
        mode = "0440";
      };
    })
  ];
}
