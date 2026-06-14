{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.searxng.enable {
    # SearXNG metasearch, bound 0.0.0.0:8888 on the LAN for two consumers:
    # (1) the LiteLLM container on the same host, hits 127.0.0.1:8888 directly;
    # (2) public traffic via Caddy → Anubis (PoW wall) → 10.0.0.5:8888,
    #     terminated at search.ethanwtodd.com.
    services.searx = {
      enable = true;
      package = pkgs.searxng;
      # Provides $SEARX_SECRET_KEY (file content: SEARX_SECRET_KEY=...).
      environmentFile = config.age.secrets.searxng-secret-key.path;

      settings = {
        server = {
          port = 8888;
          bind_address = "0.0.0.0";
          secret_key = "$SEARX_SECRET_KEY";
          base_url = "https://search.ethanwtodd.com/";
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
