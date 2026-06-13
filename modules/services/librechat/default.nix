{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.librechat.enable {
    networking.firewall.allowedTCPPorts = [ 3080 ];

    services.librechat = {
      enable = true;
      enableLocalDB = true; # provisions services.mongodb + MONGO_URI=localhost

      # CREDS_KEY, CREDS_IV, JWT_SECRET, JWT_REFRESH_SECRET, LITELLM_API_KEY.
      credentialsFile = config.age.secrets.librechat-env.path;

      env = {
        HOST = "0.0.0.0";
        ALLOW_REGISTRATION = false; # invite/registration closed; flip on briefly to add an account
      };

      settings = {
        version = "1.2.1";

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
            models = {
              default = [
                "auto"
                "smart-coder"
                "ultra-fast"
                "big-moe"
                "gpt-oss-120b"
              ];
              fetch = true;
            };
            titleConvo = true;
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
