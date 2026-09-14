{ pkgs, ... }:
{
  # tank: 5x WD40EFRX 4TB CMR raidz2 (~10.5 TiB usable). Mixed-batch drives on purpose:
  # same-batch drives hit the wear cliff together and correlated failures during resilver kill arrays.
  # Unencrypted by design (headless: native encryption needs a manual unlock per boot or a key on the box).
  # Datasets self-mount via their mountpoint property -- no fileSystems entries. Created by anton-zfs/01-create-pool.sh.
  # 'archive' (14TB SAS) is out of service: its HBA died. To restore after a replacement (LSI 9211-8i/9300-8i, IT mode):
  # re-add "archive" to extraPools + autoScrub below, `zpool import archive` (pool is wwn-keyed, controller-agnostic),
  # and point Jellyfin at /archive/video. anton-zfs/02-add-archive-pool.sh kept for a from-scratch rebuild.
  boot.zfs.extraPools = [ "tank" ];

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
