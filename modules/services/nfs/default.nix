{
  config,
  lib,
  ...
}:
let
  cfg = config.systemOptions.services.nfs;
in
{
  options.systemOptions.services.nfs = {
    server = {
      enable = lib.mkEnableOption "NFSv4 file server";
      exports = lib.mkOption {
        default = { };
        description = "Directories to share, keyed by path.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              client = lib.mkOption {
                type = lib.types.str;
                example = "10.0.0.4";
                description = "Address of the one host allowed to mount it (sec=sys trusts the client's word on uids).";
              };
              uid = lib.mkOption {
                type = lib.types.int;
                description = ''
                  Owner every access is squashed to. uids differ per host (e-play is
                  1003 on e-desktop, and anton has no user by that number), so the
                  export pins one owner instead of mapping names. Root on the client
                  is squashed too, so a `sudo rsync` lands as this owner.
                '';
              };
              gid = lib.mkOption {
                type = lib.types.int;
                default = 100;
                description = "Group every access is squashed to.";
              };
            };
          }
        );
      };
    };

    client.mounts = lib.mkOption {
      default = { };
      description = "NFSv4 shares to mount on first access, keyed by mount point.";
      example = {
        "/home/e-play/BIRDING" = "10.0.0.3:/tank/photos/BIRDING";
      };
      type = lib.types.attrsOf lib.types.str;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.server.enable {
      services.nfs.server = {
        enable = true;
        exports = lib.concatStrings (
          lib.mapAttrsToList (
            path: e:
            "${path} ${e.client}(rw,sync,no_subtree_check,all_squash,anonuid=${toString e.uid},anongid=${toString e.gid})\n"
          ) cfg.server.exports
        );
      };

      # v4 only: everything rides on 2049, so rpcbind, mountd and statd never
      # need a firewall hole.
      services.nfs.settings.nfsd.vers3 = false;
      networking.firewall.allowedTCPPorts = [ 2049 ];
    })

    # Automount, so boot never waits on the server. The mount stays hard: if the
    # server is down, readers block until it returns rather than see I/O errors
    # mid-write.
    (lib.mkIf (cfg.client.mounts != { }) {
      fileSystems = lib.mapAttrs (_: device: {
        inherit device;
        fsType = "nfs4";
        options = [
          "noauto"
          "x-systemd.automount"
          "x-systemd.mount-timeout=15s"
          "_netdev"
          "noatime"
        ];
      }) cfg.client.mounts;
    })
  ];
}
