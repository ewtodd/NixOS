{
  lib,
  osConfig,
  inputs,
  pkgs,
  ...
}:
let
  unstable = inputs.unstable.legacyPackages.${pkgs.system};
in
{
  config = lib.mkIf (osConfig.systemOptions.services.ai.enable) {
    services.ollama = {
      enable = true;
      package = unstable.ollama;
      acceleration = "rocm";
    };

    programs.opencode = {
      enable = true;
      settings = {
        theme = "system";
        provider = {
          ollama = {
            name = "Ollama (local)";
            options = {
              baseURL = "http://127.0.0.1:11434/v1";
            };
            models = {
              "llama3.2" = {
                name = "Llama 3.2";
              };
              "gpt-oss:20b" = {
                name = "GPT-oss";
              };
              "qwen3-coder:latest" = {
                name = "Qwen3-coder";
              };
            };
          };
        };
      };
    };
  };
}
