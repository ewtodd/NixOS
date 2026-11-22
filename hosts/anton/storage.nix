{ config, pkgs, ... }:
{
  boot.zfs.extraPools = [ "tank" ];

  # Media's fixed 4 TiB of tank: the quota keeps rips from filling the pool
  # the backups land on, the reservation keeps backups from squeezing out the
  # rips. The unit re-sets both on every start, so resize here, not with
  # `zfs set`. No com.sun:auto-snapshot on purpose: snapshots would pin a
  # deleted rip's space against the quota for three months.
  systemd.services.tank-media = {
    description = "tank/media dataset";
    wantedBy = [ "multi-user.target" ];
    after = [ "zfs-mount.service" ];
    path = [ config.boot.zfs.package ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      zfs list -H -o name tank/media > /dev/null 2>&1 || zfs create tank/media
      zfs set quota=4T reservation=4T recordsize=1M tank/media
      # Unmounted, install would create /tank/media on the root disk instead.
      [ "$(zfs get -H -o value mounted tank/media)" = yes ]
      install -d -o anton -g users -m 0755 /tank/media
    '';
  };

  # A scrub reads every allocated block and repairs anything raidz2 can
  # reconstruct. This is what turns silent corruption into a non-event.
  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly";
    pools = [ "tank" ];
  };

  # A degraded pool nobody notices is a lost pool.
  services.zfs.zed.settings = {
    ZED_NOTIFY_VERBOSE = true;
    ZED_SCRUB_AFTER_RESILVER = true;
  };

  # Snapshots of the backup repos in lieu of an append-only repo: `borg compact` needs the passphrase
  # server-side, which would put the encryption key on anton. Needs once per dataset:
  # zfs set com.sun:auto-snapshot=true tank/backups
  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 0;
    hourly = 0;
    daily = 7;
    weekly = 4;
    monthly = 3;
  };

  # Used drives, so watch them: short test nightly at 02:00, long test on the
  # 1st of each month at 03:00. Long tests are a full surface read and are what
  # surface latent bad sectors before a resilver has to find them the hard way.
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.wall.enable = true;
    defaults.autodetected = "-a -o on -S on -s (S/../.././02|L/../01/./03)";
  };

  environment.systemPackages = [ pkgs.smartmontools ];
}
