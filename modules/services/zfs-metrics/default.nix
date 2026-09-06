{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.zfsMetrics;
  textfileDir = config.systemOptions.services.nodeExporter.textfileDir;

  # Pool state, scrub age and per-vdev error counts from zpool, via the
  # textfile collector: node_exporter's zfs collector exposes ARC/ABD kstats
  # only, and nothing about pool health.
  zfsMetrics = pkgs.writeShellApplication {
    name = "zfs-metrics";
    runtimeInputs = [
      pkgs.zfs
      pkgs.jq
      pkgs.coreutils
      pkgs.gawk
      pkgs.smartmontools
    ];
    text = ''
      set -uo pipefail
      out="${textfileDir}/zfs.prom"
      tmp="$(mktemp "${textfileDir}/.zfs.prom.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT

      state_code() {
        case "$1" in
          ONLINE) echo 0 ;; DEGRADED) echo 1 ;; FAULTED) echo 2 ;;
          OFFLINE) echo 3 ;; UNAVAIL) echo 4 ;; REMOVED) echo 5 ;; *) echo 6 ;;
        esac
      }

      {
        echo "# HELP zfs_pool_health 0=ONLINE 1=DEGRADED 2=FAULTED 3=OFFLINE 4=UNAVAIL 5=REMOVED 6=unknown"
        echo "# TYPE zfs_pool_health gauge"
        echo "# HELP zfs_pool_raw_bytes Raw pool capacity including parity."
        echo "# TYPE zfs_pool_raw_bytes gauge"
        echo "# HELP zfs_pool_fragmentation_ratio Free-space fragmentation, 0-1."
        echo "# TYPE zfs_pool_fragmentation_ratio gauge"
        echo "# HELP zfs_pool_errors Pool-level data errors."
        echo "# TYPE zfs_pool_errors gauge"

        while IFS=$'\t' read -r name size alloc free frag _cap health; do
          [ -n "$name" ] || continue
          printf 'zfs_pool_health{pool="%s"} %s\n'              "$name" "$(state_code "$health")"
          printf 'zfs_pool_raw_bytes{pool="%s"} %s\n'           "$name" "$size"
          printf 'zfs_pool_raw_allocated_bytes{pool="%s"} %s\n' "$name" "$alloc"
          printf 'zfs_pool_raw_free_bytes{pool="%s"} %s\n'      "$name" "$free"
          printf 'zfs_pool_fragmentation_ratio{pool="%s"} %s\n' "$name" "$(awk -v f="$frag" 'BEGIN{print f/100}')"
        done < <(zpool list -Hp -o name,size,alloc,free,frag,cap,health 2>/dev/null)

        # Usable space, which is what actually matters: zpool list reports RAW
        # capacity, so on raidz2 it reads ~18 TiB for a pool that can hold 10.6.
        echo "# HELP zfs_dataset_used_bytes Space used by a dataset."
        echo "# TYPE zfs_dataset_used_bytes gauge"
        echo "# HELP zfs_dataset_available_bytes Space a dataset can still write."
        echo "# TYPE zfs_dataset_available_bytes gauge"
        while IFS=$'\t' read -r name used avail _refer; do
          [ -n "$name" ] || continue
          printf 'zfs_dataset_used_bytes{dataset="%s"} %s\n'      "$name" "$used"
          printf 'zfs_dataset_available_bytes{dataset="%s"} %s\n' "$name" "$avail"
        done < <(zfs list -Hp -o name,used,avail,refer 2>/dev/null)

        echo "# HELP zfs_vdev_errors Per-vdev error counters since the last clear."
        echo "# TYPE zfs_vdev_errors gauge"
        echo "# HELP zfs_pool_scrub_age_seconds Seconds since the last scrub finished."
        echo "# TYPE zfs_pool_scrub_age_seconds gauge"
        echo "# HELP zfs_pool_scrub_in_progress 1 while a scrub or resilver is running."
        echo "# TYPE zfs_pool_scrub_in_progress gauge"

        status="$(zpool status -j 2>/dev/null)"
        if [ -n "$status" ]; then
          # Leaf vdevs sit at varying depth, so select on shape rather than path.
          echo "$status" | jq -r '
            .pools | to_entries[] | .key as $p | .value |
            [.. | objects | select(has("read_errors") and has("name"))][] |
            "\($p)\t\(.name)\t\(.state)\t\(.read_errors)\t\(.write_errors)\t\(.checksum_errors)"
          ' 2>/dev/null | while IFS=$'\t' read -r p vd st rd wr ck; do
            printf 'zfs_vdev_errors{pool="%s",vdev="%s",type="read"} %s\n'  "$p" "$vd" "$rd"
            printf 'zfs_vdev_errors{pool="%s",vdev="%s",type="write"} %s\n' "$p" "$vd" "$wr"
            printf 'zfs_vdev_errors{pool="%s",vdev="%s",type="cksum"} %s\n' "$p" "$vd" "$ck"
            printf 'zfs_vdev_health{pool="%s",vdev="%s"} %s\n' "$p" "$vd" "$(state_code "$st")"
          done

          echo "$status" | jq -r '
            .pools | to_entries[] |
            "\(.key)\t\(.value.error_count // 0)\t\(.value.scan_stats.state // "NONE")\t\(.value.scan_stats.end_time // "")"
          ' 2>/dev/null | while IFS=$'\t' read -r p errs sstate send; do
            printf 'zfs_pool_errors{pool="%s"} %s\n' "$p" "$errs"
            if [ "$sstate" = "SCANNING" ]; then
              printf 'zfs_pool_scrub_in_progress{pool="%s"} 1\n' "$p"
            else
              printf 'zfs_pool_scrub_in_progress{pool="%s"} 0\n' "$p"
            fi
            if [ -n "$send" ]; then
              if end_epoch="$(date -d "$send" +%s 2>/dev/null)"; then
                printf 'zfs_pool_scrub_age_seconds{pool="%s"} %s\n' "$p" "$(( $(date +%s) - end_epoch ))"
              fi
            fi
          done
        fi

        # These are used drives; a rising reallocated count is the early warning
        # that matters, and it is invisible to every ZFS metric above.
        echo "# HELP smart_health_ok 1 if the drive self-assessment passes."
        echo "# TYPE smart_health_ok gauge"
        echo "# HELP smart_temperature_celsius Drive temperature."
        echo "# TYPE smart_temperature_celsius gauge"
        for dev in /dev/sd?; do
          [ -b "$dev" ] || continue
          j="$(smartctl -j -A -H -i "$dev" 2>/dev/null)" || continue
          [ -n "$j" ] || continue
          echo "$j" | jq -r --arg d "$(basename "$dev")" '
            (.serial_number // "unknown") as $s |
            [ "smart_health_ok{device=\"\($d)\",serial=\"\($s)\"} \(if .smart_status.passed then 1 else 0 end)",
              "smart_temperature_celsius{device=\"\($d)\",serial=\"\($s)\"} \(.temperature.current // 0)",
              "smart_power_on_hours{device=\"\($d)\",serial=\"\($s)\"} \(.power_on_time.hours // 0)"
            ] + [
              (.ata_smart_attributes.table // [])[] |
              select(.id == 5 or .id == 197 or .id == 198 or .id == 199) |
              "smart_attribute_raw{device=\"\($d)\",serial=\"\($s)\",name=\"\(.name)\"} \(.raw.value)"
            ] | .[]
          ' 2>/dev/null
        done
      } > "$tmp"

      # Atomic: the collector must never read a half-written file.
      chmod 644 "$tmp"
      mv -f "$tmp" "$out"
      trap - EXIT
    '';
  };
in
{
  options.systemOptions.services.zfsMetrics.enable =
    lib.mkEnableOption "ZFS pool health, scrub age and SMART metrics via the node_exporter textfile collector";

  config = lib.mkIf cfg.enable {
    systemd.services.zfs-metrics = {
      description = "Write ZFS and SMART metrics for the node_exporter textfile collector";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe zfsMetrics;
      };
    };

    systemd.timers.zfs-metrics = {
      description = "Refresh ZFS and SMART metrics";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "1min";
        AccuracySec = "10s";
      };
    };
  };
}
