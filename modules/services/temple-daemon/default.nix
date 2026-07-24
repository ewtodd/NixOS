# Temple headless daemon — systemd system service (boot-starting, no login).
#
# Run one daemon per user on each desktop machine. Authenticates to the
# temple server using the user's SSH public key.
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
      daemons = cfg.daemons;
    };
  };
}
