# Temple full-agent daemons — one system service per user on the
# workstation, each running the complete agent (loop, local tools,
# sessions, cron). The e-play daemon additionally owns the shared Signal
# presence. The TUI connects to the local daemon.
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.systemOptions.services.temple-daemon;
in
{
  imports = [ inputs.temple.nixosModules.temple-daemon ];

  config = lib.mkIf cfg.enable {
    services.temple-daemon = {
      enable = true;
      userDaemons = cfg.userDaemons;
      stateDir = cfg.stateDir;

      modelEndpoints = cfg.modelEndpoints;
      defaultModel = cfg.defaultModel;
      simpleModel = cfg.simpleModel;
      plannerModel = cfg.plannerModel;
      executorModel = cfg.executorModel;
      reviewerModel = cfg.reviewerModel;
      researcherModel = cfg.researcherModel;
      routerModel = cfg.routerModel;
      titleModel = cfg.titleModel;

      searxngUrl = cfg.searxngUrl;
      allowedDirs = cfg.allowedDirs;
      defaultPermission = cfg.defaultPermission;
      authTokenFile = cfg.authTokenFile;
      environmentFile = cfg.environmentFile;

      signal = {
        enable = cfg.signal.enable;
        owner = cfg.signal.owner;
        socketAddr = cfg.signal.socketAddr;
        defaultRecipient = cfg.signal.defaultRecipient;
        allowedSenders = cfg.signal.allowedSenders;
      };

      openWebUI = {
        enable = cfg.openWebUI.enable;
        baseUrl = cfg.openWebUI.baseUrl;
        apiKeyEnv = cfg.openWebUI.apiKeyEnv;
      };

      authorizedKeys = cfg.authorizedKeys;
    };
  };
}
