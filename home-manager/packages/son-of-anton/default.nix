{
  lib,
  osConfig,
  inputs,
  ...
}:
let
  # TUI-only trial for v's laptop: package + config + Bifrost key, no
  # gateway and no messaging platforms. Drop the deviceType check to give
  # the other v devices the same interactive agent.
  enable = osConfig.systemOptions.owner.v.enable && osConfig.systemOptions.deviceType.laptop.enable;

  # Laptops are off-LAN, so both routes go through the Caddy front for
  # Bifrost on nu; /v1 bypasses anubis and is key-protected by Bifrost.
  bifrostBase = "https://llm.ethanwtodd.com/v1";
  bifrostKeyEnv = "BIFROST_SOA_VK";
  bifrostModels = {
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
      environmentFiles = [ "/run/agenix/bifrost-keys" ];
      settings = {
        model = {
          default = "dsv4-flash";
          provider = "custom";
          reasoning_effort = "high";
        };
        custom_providers.custom = {
          base_url = bifrostBase;
          key_env = bifrostKeyEnv;
          models = bifrostModels;
        };
        auxiliary = {
          title_generation = {
            base_url = bifrostBase;
            key_env = bifrostKeyEnv;
            model = "little-titles";
            provider = "custom";
            prompt_style = "chat";
          };
          compaction = {
            base_url = bifrostBase;
            key_env = bifrostKeyEnv;
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
