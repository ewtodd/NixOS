{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.prometheus.enable {
    services.prometheus = {
      enable = true;
      port = 9090;

      # UI/API on loopback only. Grafana (co-located on nu) queries it via
      # localhost; reach the UI through an SSH tunnel when debugging PromQL.
      # No public exposure, no firewall opening.
      listenAddress = "127.0.0.1";

      retentionTime = "15d";

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "10.0.0.2:9100" ];
              labels.instance = "mu";
            }
            {
              # nu scrapes its own exporter over loopback (9100 isn't opened on
              # the router's firewall).
              targets = [ "127.0.0.1:9100" ];
              labels.instance = "nu";
            }
            {
              targets = [ "10.0.0.4:9100" ];
              labels.instance = "e-desktop";
            }
          ];
        }
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = [ "127.0.0.1:9090" ];
              labels.instance = "nu";
            }
          ];
        }
      ];
    };
  };
}
