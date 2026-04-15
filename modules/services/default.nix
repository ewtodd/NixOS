{
  config,
  lib,
  pkgs,
  ...
}:
let
  cachePort = 5000;
  cachePublicKey = "e-desktop:35K0AY3HcDOSHVQ/lklmbvmrXjIspM/LYf7yek5lyVA=";
  cacheUrl = "https://e-desktop.tail624128.ts.net";
in
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
    (lib.mkIf (config.systemOptions.services.tailscale.enable) {
      services.tailscale = {
        enable = true;
      };
    })

    # Binary cache server (e-desktop)
    (lib.mkIf (config.systemOptions.services.binaryCache.serve) {
      services.nix-serve = {
        enable = true;
        port = cachePort;
        secretKeyFile = "/etc/nix/cache-priv-key.pem";
        package = pkgs.nix-serve-ng;
      };

      services.tailscale = {
        enable = true;
      };
    })

    # Binary cache client (all other hosts)
    (lib.mkIf (config.systemOptions.services.binaryCache.consume) {
      nix.settings = {
        substituters = [ cacheUrl ];
        trusted-public-keys = [ cachePublicKey ];
      };
    })
  ];
}
