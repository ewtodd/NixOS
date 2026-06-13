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
        ALLOW_REGISTRATION = false; # invite/registration closed; flip on briefly to add an account

        # RAG API (file search). LibreChat forwards the user's JWT to rag_api,
        # which validates it with the shared JWT_SECRET. The rag-api container
        # binds 127.0.0.1:8000 (see services.ragApi).
        RAG_API_URL = "http://127.0.0.1:8000";
      };

      settings = {
        version = "1.2.1";

        # Web search is provided through the LiteLLM searxng MCP, so hide
        # LibreChat's native web-search button. fileSearch stays on (RAG).
        interface.webSearch = false;

        # LibreChat blocks internal/localhost MCP URLs by default (SSRF guard).
        # allowedAddresses exempts just our local gateway without flipping
        # allowedDomains into strict-whitelist mode (which would block the
        # public web for everything else).
        mcpSettings.allowedAddresses = [
          "127.0.0.1:4000"
          "localhost:4000"
        ];

        endpoints.custom = [
          {
            name = "LiteLLM";
            baseURL = "http://127.0.0.1:4000/v1";
            apiKey = "\${LITELLM_API_KEY}";
            modelDisplayLabel = "son of anton";
            models = {
              default = [
                "auto"
                "Qwen3-Coder-Next (smart-coder)"
                "Qwen3-30B-A3B-Instruct-2507 (ultra-fast)"
                "Qwen3.6-35B-A3B (experiment)"
                "Qwen3.5-122B-A10B (big-moe)"
                "gpt-oss-120b"
              ];
              fetch = false;
            };
            titleConvo = true;
            # Generate titles with the thinking-disabled 122b alias (same loaded
            # server, no swap) so titling doesn't spend 20s+ reasoning and time
            # out. See the classifier hook + the LiteLLM model entry.
            titleModel = "Qwen3.5-122B-A10B (titles)";
          }
        ];

        # Tools via the LiteLLM MCP gateway (fetch + searxng web_search).
        mcpServers.litellm = {
          type = "streamable-http";
          # Trailing slash is required: LiteLLM 307-redirects /mcp -> /mcp/, and
          # LibreChat's SSRF guard blocks the redirect to the private address
          # (allowedAddresses isn't consulted on redirects). Hit /mcp/ directly.
          url = "http://127.0.0.1:4000/mcp/";
          # LiteLLM's gateway answers an unauthenticated probe with an OAuth
          # challenge; without this, LibreChat tries OAuth DCR (which LiteLLM
          # doesn't support), fails, then retries with NO auth -> 500. Force
          # static auth so the x-litellm-api-key header below is actually used.
          requiresOAuth = false;
          # LiteLLM's MCP endpoint wants the key as `Authorization: Bearer <key>`
          # (its /v1 endpoints also accept x-litellm-api-key, but /mcp does not).
          headers.Authorization = "Bearer \${LITELLM_API_KEY}";
        };
      };
    };
  };
}
