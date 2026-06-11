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
