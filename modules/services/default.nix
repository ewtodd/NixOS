{
  config,
  lib,
  unstable,
  ...
}:
{
  imports = [
    ./nix-builder
  ];

  config = lib.mkMerge [
    (lib.mkIf (config.systemOptions.services.ssh.enable) {
      services.openssh = {
        enable = true;
        ports = [ 2222 ];
        settings = {
          PasswordAuthentication = true;
          KbdInteractiveAuthentication = true;
          AuthenticationMethods = "publickey password";
          AllowUsers = [
            "e-work"
            "e-play"
            "v-work"
            "v-play"
          ];
        };
      };

      networking.firewall = {
        allowedTCPPorts = [ 2222 ];
      };
    })
    (lib.mkIf (config.systemOptions.services.suspend-then-hibernate.enable) {
      services.logind.lidSwitch = lib.mkIf (config.systemOptions.deviceType.laptop.enable) "suspend-then-hibernate";

      systemd.sleep.extraConfig = ''
        HibernateDelaySec=30m
        SuspendState=mem
      '';
    })
    (lib.mkIf (config.systemOptions.services.tailscale.enable) {
      services.tailscale = {
        enable = true;
      };
    })
  ];
}
