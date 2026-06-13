{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.searxng.enable {
    # SearXNG metasearch, localhost-only. Sole consumer is the searxng MCP
    # server inside the LiteLLM container (which shares the host network
    # namespace and reaches it at 127.0.0.1:8888). No firewall opening.
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
