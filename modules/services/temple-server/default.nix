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
      environmentFile = [
        config.age.secrets.litellm-master-key.path
        config.age.secrets.signal-env.path
      ];

      # Router model mapping (fleet layout):
      #   oracle (local)       → simple queries (qwen3-4b-instruct, resident)
      #   son-of-anton         → planner + reviewer + critical (deepseek, solo)
      #   anton                → executor (qwen3.6-27b-coding) + researcher (gemma-4-31b)
      defaultModel = "deepseek-v4-flash-high";
      simpleModel = "gemma-4-31b";
      plannerModel = "deepseek-v4-flash-high";
      executorModel = "qwen3.6-27b-coding";
      reviewerModel = "deepseek-v4-flash-high";
      criticalModel = "deepseek-v4-flash-high";
      researcherModel = "gemma-4-31b";

      # Signal bot: two-way notifications + free-form inbound commands.
      signal.enable = true;
      signal.socketAddr = "10.0.0.2:7583";

      # SSH tool execution: temple-server on oracle SSHes through bastion
      # (server-mu) to reach workstations on the LAN.
      sshBastion = "deploy@10.0.0.2:2222";
      sshKeyPath = config.age.secrets.temple-ssh-key.path;

      sshTargets = [
        {
          name = "e-work@e-desktop";
          account = "e-work";
          host = "10.0.0.4";
          port = 2222;
          owner = "ethan";
          allowedDirs = [ ];
        }
        {
          name = "e-play@e-desktop";
          account = "e-play";
          host = "10.0.0.4";
          port = 2222;
          owner = "ethan";
          allowedDirs = [ ];
        }
      ];
    };
  };
}
