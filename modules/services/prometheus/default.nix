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
        {
          # LiteLLM metrics exporter (son-of-anton): token counts, request
          # counts, active sessions. Feeds the Fleet health dashboard's LLM row.
          job_name = "litellm";
          static_configs = [
            {
              targets = [ "10.0.0.5:9192" ];
              labels.instance = "son-of-anton";
            }
          ];
        }
      ];
    };
  };
}
