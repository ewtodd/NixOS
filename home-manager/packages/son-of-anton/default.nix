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
    "qwen3.8-27b" = {
      reasoning_effort = "medium";
      reasoning_efforts = [
        "none"
        "low"
        "medium"
        "xhigh"
      ];
    };
    "qwen3.8-flash-next" = {
      reasoning_effort = "medium";
      reasoning_efforts = [
        "none"
        "low"
        "medium"
        "xhigh"
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
          default = "qwen3.8-27b";
          provider = "custom";
          reasoning_effort = "medium";
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
            model = "qwen3.8-flash-next";
            provider = "custom";
            reasoning_effort = "none";
            timeout = 300;
          };
        };
      };
    };
  };
}
