{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "ethanwtodd.com";
  subdomains = [
    "ai"
    "cache"
    "cloud"
    "docs"
    "litellm"
    "mc"
    "office"
    "ssh"
    "status"
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
      # NixOS prepends `set -e` to script blocks, so this turns it back off
      # explicitly rather than relying on every failure path here happening to
      # sit in an errexit-exempt context. A single unresolvable host must not
      # abort the loop: Namecheap's API only updates records that already exist,
      # so a subdomain added here before its "A + Dynamic DNS Record" exists in
      # the panel would otherwise starve every host after it in this list until
      # someone noticed. Failures are collected and still fail the unit.
      script = ''
        set +e
        set -u
        PW=$(cat "$CREDENTIALS_DIRECTORY/pw") || {
          echo "Could not read the Namecheap DDNS credential" >&2
          exit 1
        }
        FAILED=0
        for HOST in ${lib.concatStringsSep " " subdomains}; do
          if ! RESP=$(${pkgs.curl}/bin/curl -fsS \
            "https://dynamicdns.park-your-domain.com/update?host=$HOST&domain=${domain}&password=$PW"); then
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
