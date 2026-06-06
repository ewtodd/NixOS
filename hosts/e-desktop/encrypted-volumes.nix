{ ... }:
{
  security.pam.mount = {
    enable = true;
    cryptMountOptions = [ "fsk_cipher=none" ];
    extraVolumes = [
      ''<volume user="e-play" fstype="crypt" path="/dev/disk/by-uuid/eb524bb2-0d07-4703-aae9-189de0dec3b6" mountpoint="/games" options="keyfile=/home/e-play/.config/luks/games.key,noatime,compress=zstd" />''
      ''<volume user="e-work" fstype="crypt" path="/dev/disk/by-uuid/d23020cf-fd52-45f5-9262-cb0e33a9b2b7" mountpoint="/labdata" options="keyfile=/home/e-work/.config/luks/labdata.key,noatime,compress=zstd" />''
      ''<volume user="e-work" fstype="crypt" path="/dev/disk/by-uuid/0d1fbd61-c2ab-4792-ab6f-310a7a609bb5" mountpoint="/analysis" options="keyfile=/home/e-work/.config/luks/analysis.key,noatime,compress=zstd" />''
    ];
  };

  systemd.tmpfiles.rules = [
    "d /games    0755 root   users - -"
    "d /labdata  0700 e-work users - -"
    "d /analysis 0700 e-work users - -"
  ];
}
