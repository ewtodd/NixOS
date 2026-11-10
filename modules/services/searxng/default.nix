{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.searxng;
in
{
  options.systemOptions.services.searxng = {
    enable = lib.mkEnableOption "SearXNG metasearch";
    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address. Loopback by default; set 0.0.0.0 + allowedClients when other hosts (e.g. the son-of-anton gateway) search through it.";
    };
    allowedClients = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "LAN addresses allowed through the firewall to port 8888.";
    };
  };

  config = lib.mkIf cfg.enable {
    # SearXNG metasearch, loopback by default. Sole consumers were local;
    # The son-of-anton gateway on e-workstation searches through it too, so the AI front
    # host binds it to the LAN.
    services.searx = {
      enable = true;
      package = pkgs.searxng;
      # Provides $SEARX_SECRET_KEY (file content: SEARX_SECRET_KEY=...).
      environmentFile = config.age.secrets.searxng-secret-key.path;

      settings = {
        server = {
          port = 8888;
          bind_address = cfg.listenAddress;
          secret_key = "$SEARX_SECRET_KEY";
          base_url = "http://127.0.0.1:8888/";
        };
        # The JSON API (?format=json) is disabled by default and must be
        # enabled explicitly.
        search.formats = [
          "html"
          "json"
        ];
        # Upstream defaults enable the engines that captcha/429 this host;
        # engines that answer but ship disabled are enabled below. Merged by
        # name.
        engines = [
          # Intermittent: 429s ("too many requests") for long stretches, then
          # answers well again. Cheap to leave in, and the best of the three
          # when it does answer.
          {
            name = "brave";
            disabled = false;
          }
          # Keyless (`require_api_key = False`), 20 results a page, and the
          # only engine here that has answered every query asked of it.
          {
            name = "google cse";
            disabled = false;
          }
          # Small index; answers only queries whose terms it happens to hold.
          {
            name = "mwmbl";
            disabled = false;
          }
          # Measured 2026-11: both answered every technical query tried, and
          # these two were the only free engines to find the right paper where
          # google cse returned one unrelated hit.
          {
            name = "yahoo";
            disabled = false;
          }
          {
            name = "privacywall";
            disabled = false;
          }
          # Disabled on measurement, not on principle: every query tried
          # (2026-11) came back as the trending carousel off Bing's homepage
          # (Taylor Swift, IMDb, Amazon, TikTok, Wells Fargo), because it
          # redirects an automated request to "/" and the parser reads that
          # page as results. Returning nothing is better than returning that,
          # and nothing is also what lets son-of-anton fall through to its own
          # DuckDuckGo fallback, which does answer.
          {
            name = "bing";
            disabled = true;
          }
          # HTTP error on every query since at least 2026-11.
          {
            name = "yep";
            disabled = true;
          }
          # CAPTCHA on every query. The harness's own DuckDuckGo fallback does
          # answer, so the block is this instance's, not the host's.
          {
            name = "duckduckgo";
            disabled = true;
          }
          {
            name = "qwant";
            disabled = true;
          }
        ];
      };
    };

    systemOptions.firewall.allowFrom = lib.mkIf (cfg.allowedClients != [ ]) {
      "8888" = cfg.allowedClients;
    };
  };
}
