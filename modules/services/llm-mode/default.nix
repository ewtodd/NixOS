{
  config,
  lib,
  pkgs,
  ...
}:

# Which model set owns son-of-anton's GPUs: `ds4` (unholy: DeepSeek-V4-Flash on both R9700s + the iGPU)
# or `qwen` (Radiance: Qwen3.8-27B on the R9700s, gufo: Qwen3.8-Flash-Next on the iGPU). The model
# services do not start on their own; `llm-mode-boot` starts the last selected mode (or the default)
# and `llm-mode ds4|qwen` switches at run time, no redeploy. unholy and the Qwen pair also conflict in
# systemd, so starting one side by hand stops the other.
let
  cfg = config.systemOptions.services.llmMode;
  svc = config.systemOptions.services;

  modes = {
    ds4 = [ "unholy.service" ];
    qwen = [
      "radiance.service"
      "gufo-strix.service"
    ];
  };
  allUnits = lib.unique (lib.concatLists (lib.attrValues modes));
  stateFile = "/var/lib/llm-mode/mode";

  # name -> (port, model) for `llm-mode status`.
  endpoints = [
    {
      unit = "unholy.service";
      port = svc.unholy.port;
    }
    {
      unit = "radiance.service";
      port = svc.radiance.port;
    }
    {
      unit = "gufo-strix.service";
      port = svc.gufoStrix.port;
    }
  ];

  # Runs as root from llm-mode@MODE.service: stop the other mode's units, start this one's (without
  # blocking on their load), remember the choice for the next boot.
  switch = pkgs.writeShellScript "llm-mode-switch" ''
    set -eu
    mode=$1
    case "$mode" in
    ${lib.concatStrings (
      lib.mapAttrsToList (m: units: ''
        ${m}) want="${lib.concatStringsSep " " units}" ;;
      '') modes
    )}
      *) echo "llm-mode: unknown mode '$mode' (${lib.concatStringsSep ", " (lib.attrNames modes)})" >&2; exit 2 ;;
    esac
    stop=""
    for u in ${lib.concatStringsSep " " allUnits}; do
      case " $want " in *" $u "*) ;; *) stop="$stop $u" ;; esac
    done
    # The other side must be gone before this one allocates its GPUs.
    [ -n "$stop" ] && ${pkgs.systemd}/bin/systemctl stop $stop
    ${pkgs.systemd}/bin/systemctl start --no-block $want
    mkdir -p /var/lib/llm-mode
    echo "$mode" > ${stateFile}
    echo "llm-mode: $mode ($want)"
  '';

  cli = pkgs.writeShellScriptBin "llm-mode" ''
    set -u
    PATH=${
      lib.makeBinPath [
        pkgs.systemd
        pkgs.curl
        pkgs.jq
        pkgs.coreutils
      ]
    }
    status() {
      echo "mode: $(cat ${stateFile} 2>/dev/null || echo "${cfg.default} (default)")"
      ${lib.concatMapStrings (e: ''
        st=$(systemctl is-active ${e.unit} 2>/dev/null)
        models=$(curl -fsS --max-time 3 http://127.0.0.1:${toString e.port}/v1/models 2>/dev/null | jq -r '[.data[].id] | join(",")' 2>/dev/null)
        printf '  %-20s %-10s :%-5s %s\n' ${e.unit} "$st" ${toString e.port} "''${models:-(not serving)}"
      '') endpoints}
    }
    case "''${1:-status}" in
      status) status ;;
      ${lib.concatStringsSep "|" (lib.attrNames modes)})
        systemctl start "llm-mode@$1.service" || exit $?
        echo "switched to $1; models load in the background (unholy ~1-2 min, radiance/gufo ~2-5 min)"
        status ;;
      *) echo "usage: llm-mode ${lib.concatStringsSep "|" (lib.attrNames modes)}|status" >&2; exit 2 ;;
    esac
  '';
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = svc.unholy.enable && svc.radiance.enable && svc.gufoStrix.enable;
        message = "services.llmMode switches between unholy and radiance + gufoStrix; enable all three.";
      }
    ];

    environment.systemPackages = [ cli ];

    # The mode decides what runs; none of the model services starts on its own.
    systemd.services = lib.mkMerge [
      (lib.genAttrs (map (lib.removeSuffix ".service") allUnits) (_: {
        wantedBy = lib.mkForce [ ];
      }))
      {
        unholy.conflicts = modes.qwen;

        "llm-mode@" = {
          description = "Switch son-of-anton's GPUs to the %i model set";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${switch} %i";
          };
        };

        llm-mode-boot = {
          description = "Start the last selected LLM mode";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "llm-mode-boot" ''
              mode=$(cat ${stateFile} 2>/dev/null || true)
              exec ${switch} "''${mode:-${cfg.default}}"
            '';
          };
        };
      }
    ];

    # Managers switch modes and stop/start the model services without sudo.
    security.polkit.extraConfig = lib.mkIf (cfg.managers != [ ]) ''
      polkit.addRule(function (action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            ${builtins.toJSON cfg.managers}.indexOf(subject.user) >= 0) {
          var unit = action.lookup("unit");
          if (${builtins.toJSON allUnits}.indexOf(unit) >= 0 || /^llm-mode@[a-z0-9]+\.service$/.test(unit)) {
            return polkit.Result.YES;
          }
        }
      });
    '';
  };
}
