# Hermes Agent wrapper: upstream gateway module + web dashboard systemd unit.
# Identity/memory seeds (SOUL.md/USER.md/MEMORY.md) must be copied to
# /var/lib/hermes/.hermes by hand; the agent mutates them at runtime.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.systemOptions.services.hermes;
  ha = config.services.hermes-agent;
in
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.hermes-agent = {
      enable = true;
      # Put `hermes` on PATH + export HERMES_HOME system-wide so an interactive
      # `hermes` TUI shares the gateway's brain/memory/config. Users must be in
      # the `hermes` group to read/write the shared state (UMask 0007).
      addToSystemPackages = true;
      settings = {
        # Brain: small always-resident local model via llama-swap.
        model = {
          default = cfg.brainModel;
          provider = "custom";
          base_url = cfg.endpoint;
        };
        # Delegation: heavy work routed to a larger local model.
        delegation = {
          base_url = cfg.endpoint;
          model = cfg.delegationModel;
        };
        # The brain gets durable memory + the user profile injected each turn.
        memory = {
          memory_enabled = true;
          user_profile_enabled = true;
        };
      };
    };

    # The upstream module supervises only `hermes gateway`. Add the web
    # dashboard, mirroring the gateway unit's user/env/hardening.
    systemd.services.hermes-dashboard = {
      description = "Hermes Agent Web Dashboard";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "hermes-agent.service"
      ];
      wants = [ "network-online.target" ];
      environment = {
        HOME = ha.stateDir;
        HERMES_HOME = "${ha.stateDir}/.hermes";
        HERMES_MANAGED = "true";
      };
      serviceConfig = {
        User = ha.user;
        Group = ha.group;
        WorkingDirectory = ha.workingDirectory;
        ExecStart = "${ha.package}/bin/hermes dashboard --host ${cfg.dashboardHost} --no-open";
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0007";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = false;
        ReadWritePaths = [
          ha.stateDir
          ha.workingDirectory
        ];
        PrivateTmp = true;
      };
      path = [
        ha.package
        pkgs.bash
        pkgs.coreutils
        pkgs.git
      ];
    };
  };
}
