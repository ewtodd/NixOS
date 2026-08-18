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
      description = "Bind address. Loopback by default; set 0.0.0.0 + openFirewall when other hosts (e.g. temple daemons) search through it.";
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    # SearXNG metasearch, loopback by default. Sole consumers were local;
    # temple daemons on e-desktop now search through it too, so oracle
    # binds it to the LAN.
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
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 8888 ];
  };
}
