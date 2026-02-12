{
  lib,
  osConfig ? null,
  unstable,
  ...
}:
let
  hasAI = if osConfig != null then (osConfig.systemOptions.services.ai.enable or false) else false;
in
{
  config = lib.mkIf hasAI {
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
              baseURL = "http://127.0.0.1:11434/v1";
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
