{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.nextcloud.enable {
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud33;

      hostName = "cloud.ethanwtodd.com";
      home = "/var/lib/nextcloud";
      https = true;

      database.createLocally = true;
      configureRedis = true;
      maxUploadSize = "2G";

      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit calendar contacts cookbook deck richdocuments;

        # Google Synchronization (import Drive/Calendar/Contacts from Google).
        # Not in the packaged app set, so fetched from upstream releases.
        # NOTE: v4.1.0 declares max-version="32"; we force-bump it to 33 so
        # `occ app:enable` accepts it on nextcloud33. This is unsupported by
        # upstream — re-check compatibility before the next Nextcloud upgrade.
        google_synchronization =
          let
            raw = pkgs.fetchNextcloudApp {
              url = "https://github.com/MarcelRobitaille/nextcloud_google_synchronization/releases/download/v4.1.0/google_synchronization.tar.gz";
              sha256 = "sha256-1+UeLE09G9gig5fA9U+9ugk6PF4ei0sLBaQxae0ERsA=";
              license = "agpl3Plus";
            };
          in
          pkgs.runCommandLocal "google_synchronization-nc33" { } ''
            cp -r ${raw} $out
            chmod -R u+w $out
            substituteInPlace $out/appinfo/info.xml \
              --replace 'max-version="32"' 'max-version="33"'
          '';
      };
      extraAppsEnable = true;
      appstoreEnable = false;

      config = {
        dbtype = "pgsql";
        adminuser = "ewtodd";
        adminpassFile = config.age.secrets.nextcloud-admin-password.path;
      };

      settings = {
        trusted_proxies = [ "10.0.0.7" ];
        overwriteprotocol = "https";
        overwritehost = "cloud.ethanwtodd.com";
        overwritecondaddr = "^10\\.0\\.0\\.7$";
        default_phone_region = "US";
      };
    };

    # Nextcloud Office backend
    services.collabora-online = {
      enable = true;
      port = 9980;
      aliasGroups = [ { host = "https://cloud.ethanwtodd.com"; } ];
      settings = {
        server_name = "office.ethanwtodd.com";
        ssl = {
          enable = false;
          termination = true;
        };
        # Allow Nextcloud to embed the editor iframe.
        net.frame_ancestors = "cloud.ethanwtodd.com";
      };
    };

    systemd.services.nextcloud-richdocuments-config = {
      description = "Configure Nextcloud Office (richdocuments) WOPI server URL";
      wantedBy = [ "multi-user.target" ];
      after = [ "nextcloud-setup.service" ];
      requires = [ "nextcloud-setup.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${config.services.nextcloud.occ}/bin/nextcloud-occ \
          config:app:set richdocuments wopi_url \
          --value "https://office.ethanwtodd.com"
      '';
    };

    networking.firewall.allowedTCPPorts = [
      80
      9980
    ];
  };
}
