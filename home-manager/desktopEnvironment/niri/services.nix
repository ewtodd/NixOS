{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
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
  };
}
