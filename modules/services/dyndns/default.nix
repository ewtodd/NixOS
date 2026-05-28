{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "ethanwtodd.com";
  subdomains = [
    "cache"
    "cloud"
    "ntfy"
    "office"
    "ssh"
  ];
in
{
  config = lib.mkIf config.systemOptions.services.dyndns.enable {
    systemd.services.namecheap-ddns = {
      description = "Update Namecheap A records for ${domain}";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        LoadCredential = "pw:${config.age.secrets.namecheap-ddns.path}";
      };
      script = ''
        set -eu
        PW=$(cat "$CREDENTIALS_DIRECTORY/pw")
        # Omitting the ip param: Namecheap uses the request's source IP.
        for HOST in ${lib.concatStringsSep " " subdomains}; do
          RESP=$(${pkgs.curl}/bin/curl -fsS \
            "https://dynamicdns.park-your-domain.com/update?host=$HOST&domain=${domain}&password=$PW")
          echo "$RESP" | ${pkgs.gnugrep}/bin/grep -q "<ErrCount>0</ErrCount>" || {
            echo "Namecheap DDNS update failed for $HOST.${domain}: $RESP" >&2
            exit 1
          }
        done
      '';
    };

    systemd.timers.namecheap-ddns = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
        Persistent = true;
      };
    };
  };
}
