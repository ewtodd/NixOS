{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "ethanwtodd.com";
  subdomains = [
    # "@" is Namecheap dynamic DNS host for the apex record, ethanwtodd.com.
    "@"
    "admin"
    "ai"
    "cache"
    "cloud"
    "docs"
    "llm"
    "mc"
    "office"
    "ssh"
    "status"
    "www"
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
      # NixOS prepends `set -e` to script blocks; turned back off explicitly. A single unresolvable host must
      # not abort the loop -- Namecheap only updates existing records, so a subdomain added here before its
      # "A + Dynamic DNS Record" exists in the panel would starve every host after it. Failures are still
      # collected and fail the unit.
      script = ''
        set +e
        set -u
        PW=$(cat "$CREDENTIALS_DIRECTORY/pw") || {
          echo "Could not read the Namecheap DDNS credential" >&2
          exit 1
        }
        FAILED=0
        for HOST in ${lib.concatStringsSep " " subdomains}; do
          # The URL carries the password, so it goes to curl on stdin (printf is a
          # builtin) rather than in argv, where /proc/<pid>/cmdline would show it.
          if ! RESP=$(printf 'url = "https://dynamicdns.park-your-domain.com/update?host=%s&domain=${domain}&password=%s"\n' \
            "$HOST" "$PW" | ${pkgs.curl}/bin/curl -fsS --config -); then
            echo "Namecheap DDNS request failed (network or HTTP) for $HOST.${domain}" >&2
            FAILED=1
            continue
          fi
          echo "$RESP" | ${pkgs.gnugrep}/bin/grep -q "<ErrCount>0</ErrCount>" || {
            echo "Namecheap DDNS update failed for $HOST.${domain}: $RESP" >&2
            FAILED=1
          }
        done
        exit $FAILED
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
