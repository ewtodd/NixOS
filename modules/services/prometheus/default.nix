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
              targets = [ "127.0.0.1:9100" ];
              labels.instance = "nu";
            }
            {
              targets = [ "10.0.0.4:9100" ];
              labels.instance = "e-desktop";
            }
            {
              targets = [ "10.0.0.3:9100" ];
              labels.instance = "anton";
            }
            {
              targets = [ "10.0.0.5:9100" ];
              labels.instance = "son-of-anton";
            }
            {
              targets = [ "10.0.0.6:9100" ];
              labels.instance = "oracle";
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
        {
          # fail2ban ban counts (SSH brute-force) from the bastion.
          job_name = "fail2ban";
          static_configs = [
            {
              targets = [ "10.0.0.2:9191" ];
              labels.instance = "mu";
            }
          ];
        }
        {
          # endlessh-go SSH tarpit: trapped-bot count + wasted-time seconds.
          job_name = "endlessh";
          static_configs = [
            {
              targets = [ "127.0.0.1:2112" ];
              labels.instance = "nu";
            }
          ];
        }
      ]
      # WireView Pro II GPU power monitor; the exporter runs on e-desktop
      # and the target is configured per host (see
      # systemOptions.services.prometheus.wireviewTarget).
      ++ lib.optionals (config.systemOptions.services.prometheus.wireviewTarget != null) [
        {
          job_name = "wireview";
          static_configs = [
            {
              targets = [ config.systemOptions.services.prometheus.wireviewTarget ];
              labels.instance = "e-desktop";
            }
          ];
        }
      ];
    };
  };
}
