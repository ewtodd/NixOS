{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf (config.systemOptions.services.ssh.enable) {
      services.openssh = {
        enable = true;
        ports = [ 2222 ];
        settings = {
          PasswordAuthentication = true;
          KbdInteractiveAuthentication = true;
          AuthenticationMethods = "password";
          AllowUsers = [
            "e-work"
            "e-play"
            "v-work"
            "v-play"
          ];
        };
      };

      networking.firewall = {
        allowedTCPPorts = [ 2222 ];
      };
    })
    (lib.mkIf (config.systemOptions.services.suspend-then-hibernate.enable) {
      services.logind.settings.Login.HandleLidSwitch =
        lib.mkIf (config.systemOptions.deviceType.laptop.enable) "suspend-then-hibernate";

      systemd.sleep.settings.Sleep = {
        AllowHibernation = "yes";
        AllowSuspendThenHibernate = "yes";
        HibernateDelaySec = if (config.systemOptions.deviceType.laptop.enable) then "1800" else "3600";
      };
    })
    (lib.mkIf (config.systemOptions.services.orgmode-sync.enable) (lib.mkMerge [
      {
        users.groups.org = { };

        services.syncthing = {
          enable = true;
          group = "org";
          dataDir = "/srv/syncthing";
          openDefaultPorts = true;
          overrideDevices = false;
          overrideFolders = false;
          settings = {
            folders = {
              "org" = {
                path = "/srv/org";
                versioning = {
                  type = "simple";
                  params.keep = "5";
                };
              };
            };
          };
        };

        systemd.tmpfiles.rules = [
          "d /srv/org 2775 syncthing org - -"
        ];
      }
      (lib.mkIf (config.systemOptions.owner.e.enable) {
        users.users.e-play.extraGroups = [ "org" ];
        users.users.e-work.extraGroups = [ "org" ];
        systemd.tmpfiles.rules = [
          "L /home/e-play/org - - - - /srv/org"
          "L /home/e-work/org - - - - /srv/org"
        ];
      })
      (lib.mkIf (!config.systemOptions.owner.e.enable) {
        users.users.v-play.extraGroups = [ "org" ];
        users.users.v-work.extraGroups = [ "org" ];
        systemd.tmpfiles.rules = [
          "L /home/v-play/org - - - - /srv/org"
          "L /home/v-work/org - - - - /srv/org"
        ];
      })
    ]))
    (lib.mkIf (config.systemOptions.services.tailscale.enable) {
      services.tailscale = {
        enable = true;
      };
    })
  ];
}
