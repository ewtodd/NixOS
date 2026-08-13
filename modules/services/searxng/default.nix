{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.searxng.enable {
    # SearXNG metasearch, bound 127.0.0.1:8888 (loopback only -- NOT public).
    # Its sole consumer is the LiteLLM container on the same host, which shares
    # the host network namespace and hits 127.0.0.1:8888 directly for the
    # web_search MCP tool. No Caddy/Anubis route fronts it.
    services.searx = {
      enable = true;
      package = pkgs.searxng;
      # Provides $SEARX_SECRET_KEY (file content: SEARX_SECRET_KEY=...).
      environmentFile = config.age.secrets.searxng-secret-key.path;

      settings = {
        server = {
          port = 8888;
          bind_address = "127.0.0.1";
          secret_key = "$SEARX_SECRET_KEY";
          base_url = "http://127.0.0.1:8888/";
        };
        # The MCP server queries the JSON API (?format=json); it is disabled by
        # default and must be enabled explicitly.
        search.formats = [
          "html"
          "json"
        ];
      };
    };
  };
}
