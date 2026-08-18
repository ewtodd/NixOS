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
      environmentFile = config.age.secrets.temple-server-env.path;
      modelEndpoints = {
        "qwen3.6-27b" = "http://10.0.0.5:8080/v1";
        "gemma-4-31b" = "http://10.0.0.5:8080/v1";
        "qwen3.6-27b-heretic" = "http://10.0.0.5:8080/v1";
        "gemma-4-31b-heretic" = "http://10.0.0.5:8080/v1";
        "qwen3.6-35b-a3b" = "http://10.0.0.5:8080/v1";
        "supra-router" = "http://127.0.0.1:8080/v1";
        "supra-title" = "http://127.0.0.1:8080/v1";
      };
      openFirewall = true;

      # Bridge temple memories to the Open WebUI on this host. The API key
      # (OPENWEBUI_API_KEY, one Open WebUI user) comes from the
      # temple-server-env agenix secret.
      openWebUI = {
        enable = true;
        baseUrl = "http://127.0.0.1:8081";
        apiKeyEnv = "OPENWEBUI_API_KEY";
      };

      defaultModel = "qwen3.6-35b-a3b";
      simpleModel = "qwen3.6-27b";
      plannerModel = "qwen3.6-35b-a3b";
      executorModel = "qwen3.6-27b";
      reviewerModel = "qwen3.6-35b-a3b";
      researcherModel = "qwen3.6-27b";
      routerModel = "supra-router";
      titleModel = "supra-title";

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
