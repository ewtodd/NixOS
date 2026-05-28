{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.grafana.enable {
    services.grafana = {
      enable = true;

      settings = {
        server = {
          # Loopback only — Caddy (co-located on nu) fronts it at
          # status.ethanwtodd.com. root_url makes Grafana emit correct links
          # and redirects behind the proxy.
          http_addr = "127.0.0.1";
          # 3000 is taken by AdGuard Home's web UI on nu, so use 3001.
          http_port = 3001;
          domain = "status.ethanwtodd.com";
          root_url = "https://status.ethanwtodd.com/";
        };

        security = {
          admin_user = "ewtodd";
          # Read at startup as the grafana user; secrets are owned by grafana.
          admin_password = "$__file{${config.age.secrets.grafana-admin-password.path}}";
          # Signs cookies and encrypts datasource secrets in Grafana's DB.
          # Must stay stable — changing it invalidates stored encrypted secrets.
          secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
        };

        # Login required; no anonymous access (system metrics stay private).
        "auth.anonymous".enabled = false;
        analytics.reporting_enabled = false;
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            isDefault = true;
          }
        ];
      };
    };
  };
}
