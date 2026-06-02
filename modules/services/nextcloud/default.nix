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
