{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.jellyfin;
in
{
  options.systemOptions.services.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin media server";
    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/archive/video";
      description = ''
        Where the library lives. Defaults to the archive pool's video dataset,
        which does not exist until the 14 TB drive is installed -- Jellyfin
        starts fine without it and simply has no libraries configured.
      '';
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8096;
      description = "HTTP port. LAN only; nothing here is exposed publicly.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = false; # opened explicitly below, LAN-scoped intent
      user = "jellyfin";
      group = "jellyfin";
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Intel QSV for transcoding. This box is an i3-12100T (Alder Lake, UHD 730),
    # which unlike tony's Comet Lake does have AV1 decode and a much stronger
    # media engine -- so transcoding belongs here, not on the TV client.
    #
    # It matters more than it looks: DVD rips are MPEG-2, which no browser can
    # decode, so the Jellyfin web UI will transcode every one of them. Without
    # hardware acceleration that is pure CPU.
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
      ];
    };
    users.users.jellyfin.extraGroups = [
      "video"
      "render"
    ];

    # The media directory may not exist yet; create the mount point so Jellyfin
    # has something to point a library at once the drive is in.
    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0755 jellyfin jellyfin - -"
    ];
  };
}
