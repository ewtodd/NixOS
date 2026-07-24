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
      ];

      # Router model mapping (fleet layout):
      #   son-of-anton (ROCm, Strix Halo 128GB):
      #     - deepseek-v4-flash (planner + reviewer + critical, always-resident)
      #     - gemma-4-12b-router (router + title classifier, always-resident)
      #   anton (Vulkan, R9700):
      #     - qwen3.6-27b-coding (executor)
      #     - gemma-4-31b (simple queries + researcher)
      defaultModel = "qwen3.6-27b-coding";
      simpleModel = "gemma-4-31b";
      plannerModel = "deepseek-v4-flash-high";
      executorModel = "qwen3.6-27b-coding";
      reviewerModel = "deepseek-v4-flash-high";
      criticalModel = "deepseek-v4-flash-high";
      researcherModel = "gemma-4-31b";
      routerModel = "gemma-4-12b-router";

      # Signal bot: two-way notifications + free-form inbound commands.
      signal.enable = true;
      signal.socketAddr = "10.0.0.2:7583";

      # The cron smart-flake-update runs `nix flake update --flake /etc/nixos`
      # as the temple user — mark the repo safe for libgit2's ownership check.
      gitSafeDirectories = [ "/etc/nixos" ];

      # Daemon authentication: public keys for each user's client daemon.
      # Reuses the same SSH keys already defined in secrets.nix.
      # TUI clients auto-discover ~/.ssh/id_ed25519.pub and send it.
      daemonAuthorizedKeys = {
        ethan = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH"
        ];
        val = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhKUIc/JCW80ZOcEnL4mTFx35bp/AyRYVtJXpdamnDB" ];
      };
    };
  };
}
