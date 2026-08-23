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
  pkgs,
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

    # Each profile works in its user's home. POSIX ACLs grant the service
    # user rwx there without touching mode bits (sshd StrictModes stays
    # happy — homes remain 700 to the owner's group).
    systemd.tmpfiles.rules = lib.mapAttrsToList (
      name: profile: "a+ ${profile.workingDirectory} - - - - u:son-of-anton:rwx"
    ) cfg.profiles;

    # Provision each profile: its own SON_OF_ANTON_HOME under the gateway
    # home's profiles/ dir, a config.yaml (the shared settings + the
    # profile's terminal.cwd), and its own .env (same secrets as the
    # default profile).
    system.activationScripts."son-of-anton-profiles" =
      lib.stringAfter
        (
          [ "son-of-anton-setup" ]
          ++ lib.optional (config.system.activationScripts ? setupSecrets) "setupSecrets"
        )
        (
          lib.concatMapStringsSep "\n" (
            name:
            let
              profile = cfg.profiles.${name};
              profileDir = "/var/lib/son-of-anton/.son-of-anton/profiles/${name}";
              profileConfig = (pkgs.formats.yaml { }).generate "profile-${name}-config.yaml" (
                lib.recursiveUpdate cfg.settings { terminal.cwd = profile.workingDirectory; }
              );
            in
            ''
              mkdir -p ${profileDir}
              cp ${profileConfig} ${profileDir}/config.yaml
              : > ${profileDir}/.env
              ${
                lib.concatMapStringsSep " " (f: "cat ${f}") cfg.environmentFiles
              } >> ${profileDir}/.env 2>/dev/null || true
              ${lib.concatStringsSep "\n" (
                lib.mapAttrsToList (k: v: "echo '${k}=${v}' >> ${profileDir}/.env") cfg.environment
              )}
              chown -R son-of-anton:son-of-anton ${profileDir}
              chmod 640 ${profileDir}/config.yaml
              chmod 600 ${profileDir}/.env
            ''
          ) (builtins.attrNames cfg.profiles)
        );
  };
}
