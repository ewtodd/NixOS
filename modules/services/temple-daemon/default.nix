# Temple agent daemon — one shared instance on the workstation, running
# under its own service account. Session isolation is per authenticated
# TUI client (pubkey owner); Signal handles all sessions with owner labels.
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
      serviceUser = cfg.serviceUser;
      stateDir = cfg.stateDir;
      listen = cfg.listen;

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
      supplementaryGroups = cfg.supplementaryGroups;
      readWritePaths = cfg.readWritePaths;
      gitSafeDirectories = cfg.gitSafeDirectories;

      signal = {
        enable = cfg.signal.enable;
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
