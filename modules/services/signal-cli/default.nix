# signal-cli daemon module.
# Runs signal-cli in JSON-RPC daemon mode as a systemd service.
#
# One-time registration (before enabling the service):
#   1. Get a phone number for the bot (VoIP or spare SIM)
#   2. Run as the signal-cli user:
#        sudo -u signal-cli signal-cli -u +NUMBER --data-dir /var/lib/signal-cli/data register
#      (receives SMS with verification code)
#   3. Verify:
#        sudo -u signal-cli signal-cli -u +NUMBER --data-dir /var/lib/signal-cli/data verify CODE
#   4. Create an agenix secret with SIGNAL_PHONE=+NUMBER and point
#      environmentFile at it, then enable this service.
#
# Alternatively, link as a secondary device to your existing Signal account
# using `signal-cli -u +NUMBER link -n "renco"` and scanning the QR code.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.signal-cli;
  port = toString (lib.last (lib.splitString ":" cfg.socketAddr));
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.signal-cli ];

    users.users.signal-cli = {
      isSystemUser = true;
      group = "signal-cli";
      description = "signal-cli daemon";
      home = cfg.dataDir;
    };
    users.groups.signal-cli = { };

    systemd.services.signal-cli = {
      description = "signal-cli JSON-RPC daemon (Signal bot backend)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        User = "signal-cli";
        Group = "signal-cli";
        # ${SIGNAL_PHONE} is substituted from the EnvironmentFile at runtime
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.signal-cli}/bin/signal-cli"
          "-u \${SIGNAL_PHONE}"
          "--data-dir ${cfg.dataDir}/data"
          "daemon"
          "--tcp=${cfg.socketAddr}"
        ];
        Restart = "always";
        RestartSec = "10s";

        StateDirectory = "signal-cli";
        StateDirectoryMode = "0750";

        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      }
      // (lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      });
    };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall (lib.toInt port);
  };
}
