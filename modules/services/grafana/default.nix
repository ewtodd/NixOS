{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Dashboards are Nix attrsets; pkgs.formats.json renders them at build time
  # and the directory of generated files is what Grafana provisions from.
  dashboards = {
    anton-storage = import ./dashboards/anton-storage.nix;
    bot-defense = import ./dashboards/bot-defense.nix;
    fleet-health = import ./dashboards/fleet-health.nix;
  };
  dashboardDir = pkgs.linkFarm "grafana-dashboards" (
    lib.mapAttrsToList (name: dashboard: {
      name = "${name}.json";
      path = (pkgs.formats.json { }).generate "${name}.json" dashboard;
    }) dashboards
  );
in
{
  config = lib.mkIf config.systemOptions.services.grafana.enable {
    services.grafana = {
      enable = true;

      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3001;
          domain = "status.ethanwtodd.com";
          root_url = "https://status.ethanwtodd.com/";
        };

        security = {
          admin_user = "ewtodd";
          admin_password = "$__file{${config.age.secrets.grafana-admin-password.path}}";
          secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
        };

        "auth.anonymous".enabled = false;
        analytics.reporting_enabled = false;

        dashboards.default_home_dashboard_path = "${dashboardDir}/fleet-health.json";
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            uid = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            isDefault = true;
          }
        ];
        dashboards.settings.providers = [
          {
            name = "nixos";
            options.path = dashboardDir;
            options.foldersFromFilesStructure = false;
          }
        ];
      };
    };
  };
}
