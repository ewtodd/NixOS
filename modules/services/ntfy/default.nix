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

        # Co-located with Caddy on nu, so bind loopback only — Caddy proxies
        # to it locally and nothing else should reach it. No firewall opening
        # (important: nu is WAN-facing).
        listen-http = "127.0.0.1:2586";

        # TLS terminates at Caddy; trust its X-Forwarded-* headers for
        # rate-limiting and visitor accounting.
        behind-proxy = true;

        # Subscribers are open (anyone who knows a topic can read it);
        # publishing requires an authenticated user. Users/tokens are
        # provisioned out-of-band via the `ntfy` CLI (see runbook).
        auth-default-access = "read-only";
      };
    };
  };
}
