{
  config,
  lib,
  ...
}:
let
  cfg = config.systemOptions.services.deploy;
  # The two YubiKeys (one a spare); every login needs a touch. Not the personal
  # keys: deploy is root-equivalent, and those sit unencrypted where agents run.
  deployerKeys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJ0M0GXDN+hVWHaMg2DkFQtBg6u9MJ2PIuN+pK5DmQqJAAAABHNzaDo= deploy-yubikey-1"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGMM4VEeZY7h9GKmtfW79HAr1PWK78Y72JW1ID0BNlQ8AAAABHNzaDo= deploy-yubikey-2"
  ];

  activationRules = [
    {
      users = [ "deploy" ];
      commands = [
        {
          command = "/nix/store/*/bin/switch-to-configuration";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nix-env";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/nix/store/*/bin/nix-env";
          options = [ "NOPASSWD" ];
        }
        # buildOnTarget hosts: colmena escalates the on-target
        # build with sudo when the daemon considers deploy untrusted.
        {
          command = "/run/current-system/sw/bin/nix-store";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/nix/store/*/bin/nix-store";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nix";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/nix/store/*/bin/nix";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
in
{
  config = lib.mkIf cfg.enable {
    users.users.deploy = {
      isNormalUser = true;
      description = "Colmena deploy user";
      openssh.authorizedKeys.keys = deployerKeys;
    };

    nix.settings.trusted-users = [ "deploy" ];

    services.openssh.settings.AllowUsers = [ "deploy" ];

    security.sudo.extraRules = activationRules;
    security.sudo-rs.extraRules = activationRules;
  };
}
