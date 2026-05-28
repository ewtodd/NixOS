{
  config,
  lib,
  pkgs,
  ...
}:
let
  cachePort = 5000;
  cachePublicKey = "e-desktop:35K0AY3HcDOSHVQ/lklmbvmrXjIspM/LYf7yek5lyVA=";
  cacheUrl = "https://cache.ethanwtodd.com";
in
{
  imports = [
    ./adguard
    ./bastion
    ./dyndns
    ./grafana
    ./nextcloud
    ./node-exporter
    ./ntfy
    ./prometheus
    ./reverse-proxy
    ./router
    ./wakeable
  ];

  config = lib.mkMerge [
    (lib.mkIf (config.systemOptions.services.ssh.enable) {
      services.openssh = {
        enable = true;
        ports = [ 2222 ];
        settings = {
          PasswordAuthentication = true;
          KbdInteractiveAuthentication = true;
          # Default behavior (no AuthenticationMethods set) is "any one method
          # works" — both publickey and password are accepted. ProxyJump from
          # outside needs publickey to succeed non-interactively; password
          # stays as a fallback for recovery. The bastion module overrides
          # this with mkForce "publickey" on mu.
          AllowUsers = [
            "e-work"
            "e-play"
            "v-work"
            "v-play"
            "nu"
            "mu"
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

    # Binary cache server (e-desktop). Public traffic terminates at Caddy on
    # the router (server-nu) and is forwarded over the trusted LAN, so we
    # open the cache port on the firewall — the Tailscale funnel that used
    # to front this is no longer needed.
    (lib.mkIf (config.systemOptions.services.binaryCache.serve) {
      services.nix-serve = {
        enable = true;
        port = cachePort;
        secretKeyFile = "/etc/nix/cache-priv-key.pem";
        package = pkgs.nix-serve-ng;
      };

      networking.firewall.allowedTCPPorts = [ cachePort ];
    })

    # Binary cache client (all other hosts)
    (lib.mkIf (config.systemOptions.services.binaryCache.consume) {
      nix.settings = {
        substituters = [ cacheUrl ];
        trusted-public-keys = [ cachePublicKey ];
        connect-timeout = 5;
        download-attempts = 1;
      };
    })
  ];
}
