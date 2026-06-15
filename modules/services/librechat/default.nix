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
                "auto" # classifier-routed (see litellm-proxy auto_router.py)
                "Qwen3.6-35B-A3B (default)"
                "Qwen3-Coder-Next (smart-coder)"
                "Qwen3-30B-A3B-Instruct-2507 (ultra-fast)"
                "Qwen3.5-122B-A10B (big-moe)"
                "gpt-oss-120b"
                "NVIDIA-Nemotron-3-Super-120B-A12B"
                "Mistral-Small-4-119B (vision)"
                "Mistral-Medium-3.5-128B (vision)"
                "Step-3.7-Flash (vision)"
                "MiniMax-M2.7 (uncensored)"
              ];
              fetch = false;
            };
            titleConvo = true;
            # Title with the tiny (~0.6GB) Qwen3-0.6B model, which is
            # `alwaysResident` in the llama-swap matrix: it's ANDed into every
            # set, so it co-resides alongside whatever chat/coder model a session
            # uses — including the `solo` ~85GB+ models — and is never evicted.
            # That fixes the eviction the old 30B title model caused once the
            # main coder went `solo` (the 30B was too big to ride along). Its
            # reasoning is forced off server-side so titles return in ~1s.
            #
            # A dedicated "(titles)" alias keeps titling OUT of any routing logic
            # so a failed title request can't cascade into loading a big model.
            titleModel = "Qwen3-0.6B (titles)";
          }
        ];

        # One entry PER MCP server instead of a single aggregated gateway, so
        # each shows up as an individually-toggleable server in LibreChat (run
        # general chat with just fetch+searxng and drop the rest to shrink the
        # tool surface that drives agents into LangGraph recursion loops). All
        # five hit the same LiteLLM endpoint; the `x-mcp-servers` header scopes
        # each connection to one underlying server (LiteLLM's per-server filter).
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
              # Trailing slash is required: LiteLLM 307-redirects /mcp -> /mcp/, and
              # LibreChat's SSRF guard blocks the redirect to the private address
              # (allowedAddresses isn't consulted on redirects). Hit /mcp/ directly.
              url = "http://127.0.0.1:4000/mcp/";
              # LiteLLM's gateway answers an unauthenticated probe with an OAuth
              # challenge; without this, LibreChat tries OAuth DCR (which LiteLLM
              # doesn't support), fails, then retries with NO auth -> 500. Force
              # static auth so the headers below are actually used.
              requiresOAuth = false;
              headers = {
                # /mcp wants the key as `Authorization: Bearer <key>`.
                Authorization = "Bearer \${LITELLM_API_KEY}";
                # Scope this connection to just one of LiteLLM's MCP servers.
                "x-mcp-servers" = server;
              };
            });
      };
    };
  };
}
