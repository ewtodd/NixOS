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
    # Build server configuration (e-desktop)
    # Accepts remote builds from other machines
    (lib.mkIf cfg.server.enable {
      # Create a dedicated nix-builder user for remote builds
      users.users.nix-builder = {
        isNormalUser = true;
        description = "Nix remote builder";
        openssh.authorizedKeys.keys = cfg.server.authorizedKeys;
        # No password, SSH key only
      };

      # Allow nix-builder to perform builds
      nix.settings.trusted-users = [ "nix-builder" ];

      # Ensure SSH is available for the builder
      services.openssh = {
        enable = true;
        settings = {
          AllowUsers = lib.mkAfter [ "nix-builder" ];
        };
      };
    })

    # Build client configuration (other hosts)
    # Offloads builds to e-desktop
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

      # SSH config for root to connect to the builder on port 2222
      programs.ssh.extraConfig = ''
        Host ${cfg.client.builderHostName}
          Port 2222
      '';
    })
  ];
}
