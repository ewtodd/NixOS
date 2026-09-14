{ ... }:
{
  # /games and /labdata (4TB WD SN5100) unlock AT BOOT, not at login: son-of-anton-work reads
  # /labdata/ANSG/YAP-Final at boot before any login, and the 03:00 backup needs to see the data.
  # Key files stay in the homes; cryptsetup-generator emits RequiresMountsFor for each key path.
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
