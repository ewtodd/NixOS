{ ... }:
{
  # /games and /labdata live on the 4TB WD SN5100, unlocked AT BOOT.
  #
  # They used to be pam_mount volumes (mounted at login). That broke when
  # e-work's research moved to /labdata: son-of-anton-work starts at boot and
  # reads /labdata/ANSG/YAP-Final, which did not exist until login. Boot
  # unlock restores the guarantee and lets the 03:00 backup see the data.
  #
  # Key files stay in the homes; cryptsetup-generator emits RequiresMountsFor
  # for each key path, so ordering is handled.
  environment.etc."crypttab".text = ''
    games   UUID=eb524bb2-0d07-4703-aae9-189de0dec3b6 /home/e-play/.config/luks/games.key   luks,discard
    labdata UUID=d23020cf-fd52-45f5-9262-cb0e33a9b2b7 /home/e-work/.config/luks/labdata.key luks,discard
  '';

  # nofail: boot even if a data volume does not unlock; consumers declare
  # RequiresMountsFor so they wait instead of reading an empty path.
  fileSystems."/games" = {
    device = "/dev/mapper/games";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      "nofail"
      "x-systemd.device-timeout=30s"
    ];
  };

  fileSystems."/labdata" = {
    device = "/dev/mapper/labdata";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      "nofail"
      "x-systemd.device-timeout=30s"
    ];
  };

  # Without this, son-of-anton-work reads an empty /labdata instead of waiting.
  systemd.services.son-of-anton-work.unitConfig.RequiresMountsFor = "/labdata";

  systemd.tmpfiles.rules = [
    "d /games    0755 root   users - -"
    "d /labdata  0700 e-work users - -"
  ];
}
