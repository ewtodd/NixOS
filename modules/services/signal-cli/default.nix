# signal-cli HTTP JSON-RPC daemon (SSE receive stream): the interface the son-of-anton Signal adapter speaks.
# One-time registration before enabling (as the signal-cli user; VoIP or spare SIM number):
#   signal-cli -u +NUMBER --data-dir /var/lib/signal-cli/data register && ... verify CODE
# then put SIGNAL_PHONE=+NUMBER in an agenix secret pointed at environmentFile.
# Alternative: link as secondary device -- signal-cli -u +NUMBER link -n "renco" (scan QR).
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
          "--http=${cfg.socketAddr}"
          # Mark incoming messages read (delivery receipts are sent by
          # default; this adds read receipts too) — the bot's message
          # "presence" signal, in place of typing indicators.
          "--send-read-receipts"
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
