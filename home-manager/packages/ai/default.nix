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
      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "16384";
      };
    };

    programs.opencode = {
      enable = true;
      settings = {
        theme = "system";
        provider = {
          ollama = {
            name = "Ollama (local)";
            npm = "@ai-sdk/openai-compatible";
            options = {
              baseURL = "http://127.0.0.1:11434";
            };
            models = {
              "llama3.2" = {
                name = "Llama 3.2";
                options = {
                  num_ctx = 16384;
                };
              };
              "gpt-oss:20b" = {
                name = "GPT-oss";
                options = {
                  num_ctx = 16384;
                };
              };
              "qwen3-coder:latest" = {
                name = "Qwen3-coder";
                options = {
                  num_ctx = 16384;
                };
              };
            };
          };
        };
      };
    };
  };
}
