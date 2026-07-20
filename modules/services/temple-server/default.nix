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
      # litellm-master-key contains LITELLM_MASTER_KEY=sk-...
      # signal-env contains SIGNAL_RECIPIENT=+1...
      # Both are provisioned by the secrets module with appropriate ownership.
      environmentFile = [
        config.age.secrets.litellm-master-key.path
        config.age.secrets.signal-env.path
      ];

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

      # Signal bot: two-way notifications + free-form inbound commands.
      # signal-cli daemon runs on server-mu (x86_64 bastion) — oracle is
      # aarch64 where signal-cli's native lib doesn't work.
      signal.enable = true;
      signal.socketAddr = "10.0.0.2:7583";
    };
  };
}
