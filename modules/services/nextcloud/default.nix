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

      # PostgreSQL via peer-socket auth — no DB password secret needed. The
      # module asserts createLocally is incompatible with dbpassFile.
      database.createLocally = true;
      configureRedis = true;
      maxUploadSize = "2G";

      # Strict declarative apps. Pre-packaged in nixpkgs and version-locked to
      # the chosen Nextcloud package.
      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit calendar contacts richdocuments;
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

    # Nextcloud Office backend. The browser talks to Collabora directly, so it
    # gets its own public subdomain (office.ethanwtodd.com) via the same
    # Caddy/dyndns pattern as cloud. TLS terminates at Caddy on nu — Collabora
    # listens plain HTTP on the LAN and is told it sits behind a TLS proxy.
    services.collabora-online = {
      enable = true;
      port = 9980;
      # WOPI host allowlist: Collabora only accepts edit sessions originating
      # from Nextcloud's host. Fed to coolwsd as the aliasgroup env vars.
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

    # Point the richdocuments app at the Collabora server declaratively. There
    # is no first-class NixOS option for app config, so run occ once after
    # nextcloud-setup has installed/enabled the app.
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

    # Caddy on nu reaches us on plain HTTP over the trusted LAN. mu has no
    # public interface, so this is LAN-only by topology. 9980 is Collabora.
    networking.firewall.allowedTCPPorts = [
      80
      9980
    ];
  };
}
