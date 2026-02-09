{
  config,
  lib,
  ...
}:
let
  cfg = config.systemOptions.services.nixBuilder;
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.server.enable {
      users.users.nix-builder = {
        isNormalUser = true;
        description = "Nix remote builder";
        openssh.authorizedKeys.keys = cfg.server.authorizedKeys;
      };

      nix.settings.trusted-users = [ "nix-builder" ];

      services.openssh = {
        enable = true;
        settings = {
          AllowUsers = lib.mkAfter [ "nix-builder" ];
        };
      };
    })

    (lib.mkIf cfg.client.enable {
      nix = {
        distributedBuilds = true;

        buildMachines = [
          {
            hostName = cfg.client.builderHostName;
            systems = [ "x86_64-linux" ];
            protocol = "ssh-ng";
            sshUser = "nix-builder";
            sshKey = cfg.client.sshKeyPath;
            maxJobs = cfg.client.maxJobs;
            supportedFeatures = [
              "nixos-test"
              "benchmark"
              "big-parallel"
              "kvm"
            ];
          }
        ];

        settings.builders-use-substitutes = true;
      };

      programs.ssh.extraConfig = ''
        Host ${cfg.client.builderHostName}
          Port 2222
      '';
    })
  ];
}
