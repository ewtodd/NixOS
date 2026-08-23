# Son of Anton gateway daemon — the successor to the temple daemon.
#
# One shared gateway instance on the workstation under its own service
# account. Messaging platforms (Signal via the mu signal-cli HTTP daemon,
# Discord/Slack when their tokens are present) + the cron scheduler run in
# this one service; interactive CLI/TUI sessions run per user with their
# own profile (~/.son-of-anton or a named profile).
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.systemOptions.services.son-of-anton;
in
{
  imports = [ inputs.son-of-anton.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.son-of-anton = {
      enable = true;
      workingDirectory = cfg.workingDirectory;
      environmentFiles = cfg.environmentFiles;
      environment = cfg.environment;
      settings = cfg.settings;
      extraPackages = cfg.extraPackages;
      addToSystemPackages = cfg.addToSystemPackages;
    };

    # Temple parity: the gateway's agent may read/write across the host
    # filesystem where the daemon did — /home (both accounts' projects)
    # and /etc/nixos (flake maintenance), beyond its own state + working
    # directory. Unix permissions still gate actual access per path.
    systemd.services.son-of-anton.serviceConfig.ReadWritePaths = [
      "/home"
      "/etc/nixos"
    ];
  };
}
