{
  lib,
  osConfig,
  inputs,
  ...
}:
let
  # TUI-only on the laptops (v's and e's): package + config + the maitred key,
  # no gateway service and no messaging platforms. e-workstation is left out
  # because its son-of-anton instances (modules/services/son-of-anton) already
  # write each account's config.toml and prune keys they do not declare.
  enable =
    (osConfig.systemOptions.owner.v.enable || osConfig.systemOptions.owner.e.enable)
    && osConfig.systemOptions.deviceType.laptop.enable;

  # Laptops are off-LAN, so both routes go through the Caddy front on nu
  # to maitred; /v1 bypasses anubis and is key-protected by maitred.
  gatewayBase = "https://llm.ethanwtodd.com/v1";
  gatewayKeyEnv = "MAITRED_KEY_SOA";
  gatewayModels = {
    # DSV4 efforts: none (chat mode), low, high (its default when thinking), max.
    "dsv4-flash" = {
      reasoning_effort = "high";
      reasoning_efforts = [
        "none"
        "low"
        "high"
        "max"
      ];
    };
  };
in
{
  imports = [ inputs.son-of-anton.homeManagerModules.default ];

  config = lib.mkIf enable {
    services.son-of-anton = {
      enable = true;
      installPackage = true;
      # Activation merges this into $SON_OF_ANTON_HOME/.env, tolerating the
      # file being absent; no gateway needs the key exported system-wide.
      environmentFiles = [ "/run/agenix/maitred-keys" ];
      settings = {
        model = {
          default = "dsv4-flash";
          provider = "custom";
          reasoning_effort = "high";
        };
        custom_providers.custom = {
          base_url = gatewayBase;
          key_env = gatewayKeyEnv;
          models = gatewayModels;
        };
        auxiliary = {
          title_generation = {
            base_url = gatewayBase;
            key_env = gatewayKeyEnv;
            # Full id: the bare name is ambiguous in maitred (little-titles-json serves the
            # same upstream model), so it 404s.
            model = "llama/little-titles";
            provider = "custom";
            prompt_style = "chat";
          };
          compaction = {
            base_url = gatewayBase;
            key_env = gatewayKeyEnv;
            model = "dsv4-flash";
            provider = "custom";
            reasoning_effort = "none";
            timeout = 300;
          };
        };
      };
    };
  };
}
