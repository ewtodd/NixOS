{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.backup;
in
{
  options.systemOptions.services.backup = {
    server = {
      enable = lib.mkEnableOption "borg repository server (receives backups from other hosts)";
      path = lib.mkOption {
        type = lib.types.str;
        default = "/tank/backups";
        description = "Directory holding one repository per client.";
      };
      clients = lib.mkOption {
        default = { };
        description = "Clients allowed to push, keyed by repository name.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.publicKey = lib.mkOption {
              type = lib.types.str;
              description = "SSH public key the client authenticates with.";
            };
          }
        );
      };
    };

    client = {
      enable = lib.mkEnableOption "nightly borg backup to a repository server";
      repo = lib.mkOption {
        type = lib.types.str;
        example = "borg@10.0.0.3:/tank/backups/e-desktop";
        description = "Repository to push to.";
      };
      paths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Paths to back up.";
      };
      exclude = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Patterns to skip.";
      };
      passphraseFile = lib.mkOption {
        type = lib.types.str;
        description = ''
          Repository passphrase; borg encrypts client-side, so the server never
          needs it. Keep a copy OFF this machine -- if the host dies you need
          the backups to recover, and the passphrase to read them.
        '';
      };
      sshKey = lib.mkOption {
        type = lib.types.str;
        default = "/etc/ssh/borg_ed25519";
        description = "Private key used to reach the repository server.";
      };
      startAt = lib.mkOption {
        type = lib.types.str;
        default = "03:00";
        description = "systemd OnCalendar expression for the nightly run.";
      };
      requiresMounts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Mount points the job must not run without: archiving an empty
          mountpoint records the tree as deleted and ages out the archives.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.server.enable {
      services.borgbackup.repos = lib.mapAttrs (name: c: {
        path = "${cfg.server.path}/${name}";
        authorizedKeys = [ c.publicKey ];
        user = "borg";
        group = "borg";
        allowSubRepos = false;
      }) cfg.server.clients;

      users.users.borg.group = "borg";
      users.groups.borg = { };

      # The module's forced command `cd`s into the repo dir but does not create
      # it, so the first connection would die on a missing directory.
      systemd.tmpfiles.rules = [
        "d ${cfg.server.path} 0755 root root - -"
      ]
      ++ lib.mapAttrsToList (
        name: _: "d ${cfg.server.path}/${name} 0700 borg borg - -"
      ) cfg.server.clients;

      # security.harden closes sshd to an AllowUsers list; append borg (lists
      # merge, so this does not replace the host's own entries).
      services.openssh.settings.AllowUsers = [ "borg" ];
    })

    (lib.mkIf cfg.client.enable {
      services.borgbackup.jobs.system = {
        inherit (cfg.client)
          paths
          exclude
          repo
          startAt
          ;
        doInit = true;
        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat ${cfg.client.passphraseFile}";
        };
        environment.BORG_RSH = "ssh -i ${cfg.client.sshKey} -o StrictHostKeyChecking=accept-new";
        # On a live desktop at least one file changes mid-read on nearly every
        # run (Signal sqlite, browser state, agents), so exit 1 (warnings) is
        # normal; only exit >= 2 fails the unit. Warnings stay in the journal.
        failOnWarnings = false;
        # "auto" skips already-compressed data -- most of this payload is
        # .root files and game assets.
        compression = "auto,zstd";
        # Checkpoints let an interrupted first run (~1.4 TiB) resume.
        extraCreateArgs = [
          "--stats"
          "--checkpoint-interval"
          "600"
        ];
        prune.keep = {
          daily = 7;
          weekly = 4;
          monthly = 6;
        };
        persistentTimer = true;
      };

      # Fail loudly rather than archive an empty mountpoint.
      systemd.services."borgbackup-job-system" = {
        unitConfig.RequiresMountsFor = cfg.client.requiresMounts;
        serviceConfig.ExecStartPre = map (
          m: "${pkgs.util-linux}/bin/mountpoint -q ${lib.escapeShellArg m}"
        ) cfg.client.requiresMounts;
      };
    })
  ];
}
