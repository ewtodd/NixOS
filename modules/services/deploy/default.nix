{
  config,
  lib,
  ...
}:
let
  cfg = config.systemOptions.services.deploy;
  deployerKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
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
