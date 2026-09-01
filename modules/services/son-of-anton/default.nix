{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.son-of-anton;

  settingsFor =
    inst:
    lib.foldl lib.recursiveUpdate cfg.settings [
      {
        terminal.cwd = inst.workingDirectory;
      }
      (lib.optionalAttrs (inst.model != "") {
        gateway.model = inst.model;
      })
      inst.settings
    ];
in
{
  imports = [ inputs.son-of-anton.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    users.groups.son-of-anton = { };

    services.son-of-anton.instances = lib.mapAttrs (name: inst: {
      enable = true;
      pruneUnmanagedSettings = true;
      inherit (inst)
        user
        createUser
        managedAccount
        son-of-antonHome
        workingDirectory
        protectedPaths
        ;
      group = "son-of-anton";

      stateDir = if inst.stateDir != "" then inst.stateDir else "/var/lib/son-of-anton-${name}";
      addToSystemPackages = false;

      environmentFiles = cfg.environmentFiles ++ inst.environmentFiles;
      environment = cfg.environment // {
        SIGNAL_DM_MODE = "ignore";
      };
      settings = settingsFor inst;
      extraPackages = cfg.extraPackages ++ inst.extraPackages;
    }) cfg.instances;
    environment.systemPackages = [ inputs.son-of-anton.packages.${pkgs.system}.default ];

    systemd.services = lib.mapAttrs' (
      name: _:
      lib.nameValuePair "son-of-anton-${name}" {
        serviceConfig = {
          ReadWritePaths = [ "/etc/nixos" ];

          InaccessiblePaths = map (p: "-${p}") (
            lib.concatMap (
              other:
              [
                other.workingDirectory
                other.son-of-antonHome
              ]
              ++ lib.optional (other.stateDir != "") other.stateDir
            ) (lib.attrValues (lib.filterAttrs (n: _: n != name) cfg.instances))
          );
        };
      }
    ) cfg.instances;
  };
}
