{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.systemOptions.services.templeServer;
in
{
  imports = [ inputs.temple.nixosModules.temple-server ];

  config = lib.mkIf cfg.enable {
    services.temple-server = {
      enable = true;
      litellmUrl = "https://llm.ethanwtodd.com";
      openFirewall = true;
      # Reuse the litellm-master-key agenix secret: its content
      # (LITELLM_MASTER_KEY=sk-...) is accepted by temple-server as a
      # fallback for LITELLM_API_KEY. The secrets module provisions this
      # path with owner=temple, group=temple, mode=0440 so the systemd
      # service (running as the `temple` user) can read it.
      environmentFile = config.age.secrets.litellm-master-key.path;

      # Router model mapping (fleet layout):
      #   oracle (local)       → simple queries (qwen3-4b-instruct, resident)
      #   son-of-anton         → planner + reviewer + critical (deepseek, solo)
      #   anton                → executor (qwen3.6-27b-coding)
      defaultModel = "deepseek-v4-flash-high";
      simpleModel = "qwen3-4b-instruct";
      plannerModel = "deepseek-v4-flash-high";
      executorModel = "qwen3.6-27b-coding";
      reviewerModel = "deepseek-v4-flash-high";
      criticalModel = "deepseek-v4-flash-high";
    };
  };
}
