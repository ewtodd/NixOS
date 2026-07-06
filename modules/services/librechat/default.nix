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
          recursionLimit = 40;
          maxRecursionLimit = 50;
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
                "gpt-oss-low"
                "gpt-oss-medium"
                "gpt-oss-high"
                "gemma-4-31b"
                "gemma-4-26b-a4b"
                "gemma-4-e4b"
                "mistral-small-4-119b"
                "minimax-m2.7"
                "qwen3-coder-next"
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
