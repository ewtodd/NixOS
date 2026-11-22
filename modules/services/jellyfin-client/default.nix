{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.jellyfinClient;
in
{
  options.systemOptions.services.jellyfinClient = {
    enable = lib.mkEnableOption "Jellyfin MPV client for the kiosk";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.jellyfin-mpv-shim ];
  };
}
