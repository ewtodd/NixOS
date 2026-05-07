{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.agenix.nixosModules.default ];

  age.identityPaths = lib.mkIf config.systemOptions.owner.e.enable [
    "/home/e-work/.ssh/id_ed25519"
  ];

  age.secrets = lib.mkIf config.systemOptions.owner.e.enable {
    onyx-ssh-config = {
      file = ../../secrets/onyx-ssh-config.age;
      owner = "e-work";
      mode = "0400";
    };
  };
}
