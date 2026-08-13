{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.adguard.enable {
    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      host = "0.0.0.0";
      port = 3000;
      settings = {
        dns = {
          bind_hosts = [ "127.0.0.1" ];
          port = 5353;
          upstream_dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          bootstrap_dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
        };
        filtering.filtering_enabled = true;
      };
    };
  };
}
