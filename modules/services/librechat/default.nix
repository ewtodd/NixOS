{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.librechat.enable {
    networking.firewall.allowedTCPPorts = [ 3080 ];

    services.meilisearch.masterKeyFile = config.age.secrets.meilisearch-api-key.path;

    services.librechat = {
      enable = true;
      enableLocalDB = true; # provisions services.mongodb + MONGO_URI=localhost

      # Message search via Meilisearch.
      meilisearch.enable = true;

      # CREDS_KEY, CREDS_IV, JWT_SECRET, JWT_REFRESH_SECRET, LITELLM_API_KEY.
      credentialsFile = config.age.secrets.librechat-env.path;

      env = {
        HOST = "0.0.0.0";
        ALLOW_REGISTRATION = false;
      };

      settings = {
        version = "1.2.1";
        interface.webSearch = false;
        mcpSettings.allowedAddresses = [
          "127.0.0.1:4000"
          "localhost:4000"
        ];

        endpoints.agents = {
          recursionLimit = 75;
          maxRecursionLimit = 100;
        };

        endpoints.custom = [
          {
            name = "LiteLLM";
            baseURL = "http://127.0.0.1:4000/v1";
            apiKey = "\${LITELLM_API_KEY}";
            modelDisplayLabel = "son of anton";
            models = {
              default = [
                "auto"
                "step-3.7-flash-low"
                "step-3.7-flash-medium"
                "step-3.7-flash-high"
                "qwen3.5-122b-a10b"
                "qwen3.6-35b-a3b-general"
                "qwen3.6-35b-a3b-coding"
                "qwen3.6-27b-general"
                "qwen3.6-27b-coding"
                "gemma-4-31b"
                "qwen3.6-27b-heretic-general"
                "qwen3.6-27b-heretic-coding"
                "gemma-4-31b-heretic"
                "gemma-4-26b-a4b"
                "gemma-4-e4b"
                "qwen3-coder-next"
                "nemotron-3-super-120b-a12b-no-thinking-general"
                "nemotron-3-super-120b-a12b-thinking-general"
                "nemotron-3-super-120b-a12b-no-thinking-coding"
                "nemotron-3-super-120b-a12b-thinking-coding"
                "deepseek-v4-flash-max"
                "deepseek-v4-flash-high"
                "deepseek-v4-flash-no-thinking"
                "minimax-m2.7"
              ];
              fetch = false;
            };
            titleConvo = true;
            titleModel = "qwen3-4b-instruct";
          }
        ];
        mcpServers =
          lib.genAttrs
            [
              "fetch"
              "searxng"
              "nixos"
              "arxiv"
              "context7"
            ]
            (server: {
              type = "streamable-http";
              url = "http://127.0.0.1:4000/mcp/";
              requiresOAuth = false;
              headers = {
                Authorization = "Bearer \${LITELLM_API_KEY}";
                "x-mcp-servers" = server;
              };
            });
      };
    };
  };
}
