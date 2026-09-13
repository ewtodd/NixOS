{ pkgs, ... }:
{
  # ── ZFS storage ────────────────────────────────────────────────────────────
  # tank: 5 x WDC WD40EFRX (4 TB, CMR) in raidz2 -- survives any two failures.
  #       12.0 TB after parity; ~10.9 TiB raw, ~10.5 TiB usable.
  #
  # The drives were bought at different times (2k to 34k power-on hours), which
  # is deliberate insurance: same-batch drives tend to reach the wear cliff
  # together, and a correlated second failure during resilver is what actually
  # kills arrays.
  #
  # Created by anton-zfs/01-create-pool.sh. Datasets carry their own mountpoint
  # property, so there are no fileSystems entries here to drift out of sync --
  # extraPools imports the pool and ZFS mounts what it holds.
  #
  # Not encrypted, deliberately: on a headless box native encryption needs either
  # a manual unlock every boot or a key on the same machine's unencrypted root,
  # which defends against very little. Shred drives at disposal instead.
  #
  # The 14 TB SAS drive (archive pool) is NOT configured here: its HBA died.
  # The card worked on the bench, then hung mid-option-ROM after the machine was
  # racked, then stopped appearing on the PCI bus entirely -- surviving a clean
  # and reseat, and with both empty root ports enumerating fine, so slot, lanes,
  # cable and drive were all eliminated. Listing the pool cost 2m17s of a
  # headless NAS being unreachable on every boot, to import something absent.
  #
  # To restore once a replacement HBA (LSI 9211-8i / 9300-8i, IT mode) is in:
  #   - add "archive" back to extraPools and autoScrub.pools below
  #   - `zpool import archive` -- the pool is keyed on wwn-0x5000cca2587032c8,
  #     so it does not care which controller the drive appears behind
  #   - point Jellyfin's library at /archive/video
  # anton-zfs/02-add-archive-pool.sh is kept for a from-scratch rebuild.
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

  # Snapshots of the backup repos, in lieu of an append-only repo: that only
  # defers deletion -- `borg compact` needs the passphrase server-side, which
  # would put the encryption key on anton.
  # Needs once per dataset: zfs set com.sun:auto-snapshot=true tank/backups
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
