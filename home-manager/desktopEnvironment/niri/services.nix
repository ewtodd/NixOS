{
  pkgs,
  lib,
  config,
  osConfig,
  inputs,
  ...
}:
let
  dms-idle-inhibit = pkgs.writeShellScript "dms-idle-inhibit" ''
    dms() { ${config.programs.dank-material-shell.package}/bin/dms "$@"; }
    i=0
    while [ $i -lt 60 ]; do
      if dms ipc call inhibit status 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q enabled; then
        exit 0
      fi
      dms ipc call inhibit enable >/dev/null 2>&1
      sleep 1
      i=$((i + 1))
    done
    exit 1
  '';
  niri-utilities = inputs.niri-utilities.packages.${pkgs.stdenv.hostPlatform.system}.niri-utilities;
  niri-tile-to-n = pkgs.writers.writePython3Bin "niri-tile-to-n" { doCheck = false; } (
    builtins.readFile ./scripts/niri_tile_to_n.py
  );
  # The tiler takes a model string (resolved to the current connector inside the
  # script) so it keeps working no matter which DP-* connector niri probes.
  niri-tile-to-n-daemon = pkgs.writeShellScript "niri-tile-to-n-daemon" ''
    sleep 2
    exec ${niri-tile-to-n}/bin/niri-tile-to-n -n 3 --output 'Sceptre F22'
  '';
  # The centering daemon compares against the IPC connector name, which can
  # change between boots (DP-5 / DP-3 / DP-1). Resolve the current connector
  # from the monitor model at runtime instead of hardcoding one name.
  niri-centering-daemon = pkgs.writeShellScript "niri-centering-daemon" ''
    niri() { ${osConfig.programs.niri.package}/bin/niri "$@"; }
    OUTPUT=""
    i=0
    while [ -z "$OUTPUT" ] && [ $i -lt 20 ]; do
      OUTPUT=$(niri msg --json outputs 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r 'to_entries[] | select(.value.model == "Sceptre O34") | .key' 2>/dev/null \
        | ${pkgs.coreutils}/bin/head -n1)
      if [ -z "$OUTPUT" ]; then
        sleep 0.5
        i=$((i + 1))
      fi
    done
    if [ -n "$OUTPUT" ]; then
      exec ${niri-utilities}/bin/niri-utilities centering-daemon --output "$OUTPUT"
    else
      exec ${niri-utilities}/bin/niri-utilities centering-daemon
    fi
  '';
  lisgd-niri = pkgs.writeShellScript "lisgd-niri" ''
    # Find the touchscreen event device via libinput
    TOUCH_DEV=$(${pkgs.libinput}/bin/libinput list-devices \
      | ${pkgs.gawk}/bin/awk '
          /Kernel:/ { kern=$NF }
          /Capabilities:[ ]+touch/ { print kern; exit }
        ')
    if [ -z "$TOUCH_DEV" ]; then
      echo "lisgd-niri: no touchscreen device found" >&2
      exit 1
    fi
    echo "lisgd-niri: using device $TOUCH_DEV" >&2
    exec ${pkgs.lisgd}/bin/lisgd -d "$TOUCH_DEV" -t 200 \
      \
      -g "1,LR,L,*,R,${osConfig.programs.niri.package}/bin/niri msg action focus-column-left" \
      -g "1,RL,R,*,R,${osConfig.programs.niri.package}/bin/niri msg action focus-column-right" \
      \
      -g "1,DU,B,*,R,${osConfig.programs.niri.package}/bin/niri msg action focus-workspace-down" \
      -g "1,UD,T,*,R,${osConfig.programs.niri.package}/bin/niri msg action focus-workspace-up" \
      \
      -g "3,LR,*,*,R,${osConfig.programs.niri.package}/bin/niri msg action switch-preset-column-width" \
      -g "3,ULDR,*,*,R,${osConfig.programs.niri.package}/bin/niri msg action expand-column-to-available-width" \
      \
      -g "3,DU,*,*,R,${osConfig.programs.niri.package}/bin/niri msg action toggle-overview" \
      \
      -g "3,URDL,*,*,R,${osConfig.programs.niri.package}/bin/niri msg action close-window"
  '';
in
{
  config = {
    services.udiskie = {
      enable = true;
      settings = {
        program_options = {
          tray = "auto";
          file_manager = "${pkgs.nautilus}/bin/nautilus";
        };
      };
    };
    services.gnome-keyring.enable = true;
    systemd.user.services.lisgd = lib.mkIf (osConfig.systemOptions.hardware.twoinone.enable) {
      Unit = {
        Description = "Touchscreen gesture daemon for niri";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${lisgd-niri}";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
    systemd.user.services.niri-centering-daemon =
      lib.mkIf (osConfig.systemOptions.owner.e.enable && osConfig.systemOptions.deviceType.desktop.enable)
        {
          Unit = {
            Description = "Auto-center daemon for niri";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${niri-centering-daemon}";
            Restart = "on-failure";
            RestartSec = 3;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
    systemd.user.services.niri-tile-to-n =
      lib.mkIf (osConfig.systemOptions.owner.e.enable && osConfig.systemOptions.deviceType.desktop.enable)
        {
          Unit = {
            Description = "Auto-tiler for niri";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${niri-tile-to-n-daemon}";
            Restart = "on-failure";
            RestartSec = 3;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
    systemd.user.services.dms-idle-inhibit =
      lib.mkIf (osConfig.systemOptions.owner.e.enable && osConfig.systemOptions.deviceType.desktop.enable)
        {
          Unit = {
            Description = "Enable DMS idle inhibit";
            After = [ "dms.service" ];
            PartOf = [ "dms.service" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${dms-idle-inhibit}";
          };
          Install.WantedBy = [ "dms.service" ];
        };
    systemd.user.services.wlinhibit =
      lib.mkIf (osConfig.systemOptions.owner.e.enable && osConfig.systemOptions.deviceType.desktop.enable)
        {
          Unit = {
            Description = "Wayland idle inhibitor";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${pkgs.wlinhibit}/bin/wlinhibit";
            Restart = "always";
            RestartSec = 3;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
  };
}
