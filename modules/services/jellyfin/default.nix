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
    # Intel QSV (i3-12100T Alder Lake, UHD 730 -- AV1 decode, unlike tony's Comet Lake): transcoding belongs
    # here, not on the TV client. DVD rips are MPEG-2, which no browser decodes, so the web UI transcodes
    # every one of them; without hardware acceleration that is pure CPU.
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

    # No tmpfiles rule for mediaDir on purpose. It is a ZFS dataset mountpoint,
    # and a `d` rule re-applies ownership on every activation -- so it would
    # chown the mounted dataset root out from under whoever writes the rips.
    # The storage layer owns that path; this module only reads it.
  };
}
