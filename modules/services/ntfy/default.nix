{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.ntfy.enable {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://ntfy.ethanwtodd.com";

        listen-http = "127.0.0.1:2586";

        behind-proxy = true;

        auth-default-access = "read-only";
      };
    };
  };
}
