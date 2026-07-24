# Temple headless daemon — systemd system service (boot-starting, no login).
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.systemOptions.services.temple-daemon;
in
{
  imports = [ inputs.temple.nixosModules.temple-daemon ];

  config = lib.mkIf cfg.enable {
    services.temple-daemon = {
      enable = true;
      server = "https://temple.ethanwtodd.com";
      userDaemons = cfg.userDaemons;
    };
  };
}
