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
                "Step-3.7-Flash (low)"
                "Step-3.7-Flash (medium)"
                "Step-3.7-Flash (high)"
                "Qwen3.5-122B-A10B (large moe)"
                "Qwen3.6-35B-A3B (moe general)"
                "Qwen3.6-35B-A3B (moe coding)"
                "Qwen3.6-27B (dense general)"
                "Qwen3.6-27B (dense coding)"
                "GPT-OSS (low)"
                "GPT-OSS (medium)"
                "GPT-OSS (high)"
                "Gemma-4-31B (dense general)"
                "Gemma-4-26B-A4B (moe general)"
                "Gemma-4-E4B (fast)"
                "Mistral-Small-4-119B (vision)"
                "Mistral-Medium-3.5-128B (vision)"
                "MiniMax-M2.7 (uncensored)"
              ];
              fetch = false;
            };
            titleConvo = true;
            titleModel = "Qwen3-4B-Instruct (titles)";
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
