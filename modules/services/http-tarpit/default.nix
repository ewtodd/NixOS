{
  config,
  lib,
  pkgs,
  ...
}:
let
  tarpitPython = pkgs.python3.withPackages (ps: [ ps.prometheus-client ]);
in
{
  config = lib.mkIf config.systemOptions.services.httpTarpit.enable {
    # Listens on loopback only; Caddy sends the WAN catch-all here after
    # Anubis, so nothing reaches it directly from outside the host.
    systemd.services.http-tarpit = {
      description = "HTTP tarpit (endless slow-drip responses for scanners)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${tarpitPython}/bin/python ${./http_tarpit.py}";
        Restart = "on-failure";
        RestartSec = "5s";

        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        LimitNOFILE = 65536;
      };
    };
  };
}
