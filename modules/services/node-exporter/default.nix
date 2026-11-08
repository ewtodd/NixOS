{
  config,
  lib,
  pkgs,
  ...
}:
let
  textfileDir = config.systemOptions.services.nodeExporter.textfileDir;

  # node_exporter's drm collector labels amdgpu stats by DRM card number only, which follows driver
  # probe order; hwmon labels the same GPUs by PCI address. This writes the card -> PCI device map as
  # drm_card_device_info{card,device,driver} so llmtop can join the two.
  drmCardMap = pkgs.writeShellScript "drm-card-map" ''
    out=${textfileDir}/drm-cards.prom
    tmp=$(${pkgs.coreutils}/bin/mktemp ${textfileDir}/.drm-cards.XXXXXX)
    {
      echo '# HELP drm_card_device_info DRM card number to PCI device and driver.'
      echo '# TYPE drm_card_device_info gauge'
      for card in /sys/class/drm/card[0-9]*; do
        name=''${card##*/}
        case $name in *-*) continue ;; esac
        [ -e "$card/device/driver" ] || continue
        device=$(${pkgs.coreutils}/bin/basename "$(${pkgs.coreutils}/bin/readlink -f "$card/device")")
        driver=$(${pkgs.coreutils}/bin/basename "$(${pkgs.coreutils}/bin/readlink -f "$card/device/driver")")
        echo "drm_card_device_info{card=\"$name\",device=\"$device\",driver=\"$driver\"} 1"
      done
    } > "$tmp"
    ${pkgs.coreutils}/bin/chmod 0644 "$tmp"
    ${pkgs.coreutils}/bin/mv "$tmp" "$out"
  '';
in
{
  options.systemOptions.services.nodeExporter.textfileDir = lib.mkOption {
    type = lib.types.str;
    default = "/var/lib/node-exporter/textfile";
    description = ''
      Directory the textfile collector reads, for metrics node_exporter has no
      collector for (ZFS pool health, for one: the built-in zfs collector
      exposes ARC/ABD kstats only, nothing about pool state).
    '';
  };

  config = lib.mkIf config.systemOptions.services.nodeExporter.enable {
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = [
        "drm"
        "systemd"
        "textfile"
      ];
      extraFlags = [
        "--collector.textfile.directory=${textfileDir}"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${textfileDir} 0755 root root - -"
    ];

    systemd.services.drm-card-map = {
      description = "DRM card to PCI device map for node_exporter";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = drmCardMap;
      };
    };
    systemd.timers.drm-card-map = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "10min";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (!config.systemOptions.services.router.enable) [
      9100
    ];
  };
}
