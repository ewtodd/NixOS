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
      litellmUrl = "http://127.0.0.1:4000";
      openFirewall = true;
      environmentFile = [
        config.age.secrets.litellm-master-key.path
      ];

      defaultModel = "qwen3.6-27b-coding";
      simpleModel = "gemma-4-12b-it-qat";
      plannerModel = "deepseek-v4-flash";
      executorModel = "qwen3.6-27b-coding";
      reviewerModel = "deepseek-v4-flash";
      criticalModel = "deepseek-v4-flash";
      researcherModel = "deepseek-v4-flash";
      routerModel = "gemma-4-12b-it-qat";

      # Signal bot: two-way notifications + free-form inbound commands.
      signal.enable = true;
      signal.socketAddr = "10.0.0.2:7583";

      # The cron smart-flake-update runs `nix flake update --flake /etc/nixos`
      # as the temple user — mark the repo safe for libgit2's ownership check.
      gitSafeDirectories = [ "/etc/nixos" ];

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
