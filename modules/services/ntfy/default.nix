{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.ntfy.enable {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://ntfy.ethanwtodd.com";

        # Bind all interfaces; exposure is controlled by the firewall (mu has
        # no WAN interface — only nu does — and reaches us over the trusted
        # LAN). Same rationale as the AdGuard module.
        listen-http = "0.0.0.0:2586";

        # TLS terminates at Caddy on nu; trust its X-Forwarded-* headers for
        # rate-limiting and visitor accounting.
        behind-proxy = true;

        # Subscribers are open (anyone who knows a topic can read it);
        # publishing requires an authenticated user. Users/tokens are
        # provisioned out-of-band via the `ntfy` CLI (see runbook).
        auth-default-access = "read-only";
      };
    };

    # Reachable from Caddy on nu over the trusted LAN.
    networking.firewall.allowedTCPPorts = [ 2586 ];
  };
}
