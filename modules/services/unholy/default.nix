{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.systemOptions.services.unholy;

  unholy = inputs.unholy.lib.${pkgs.stdenv.hostPlatform.system}.mkUnholy { inherit pkgs; };

  unitName = name: "unholy-${name}";
  units = map (name: "${unitName name}.service") (lib.attrNames cfg.instances);

  serveArgs =
    inst:
    [
      "--model ${inst.model}"
      "--host ${if cfg.lanExpose then "0.0.0.0" else "127.0.0.1"}"
      "--port ${toString inst.port}"
      "--served-model-name ${inst.servedModelName}"
      "--kv-tokens ${toString inst.kvTokens}"
      "--max-model-len ${toString inst.maxModelLen}"
      "--max-num-seqs ${toString inst.maxNumSeqs}"
      "--max-batch-tokens ${toString inst.maxBatchTokens}"
      "--prefix-snapshots ${toString inst.prefixSnapshots}"
      "--spec-drafts ${toString inst.specDrafts}"
    ]
    ++ lib.optionals (inst.exl3 != null) [ "--exl3 ${inst.exl3}" ]
    ++ lib.optionals (inst.profile != null) [ "--profile ${inst.profile}" ]
    ++ inst.extraFlags;
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          let
            s = config.systemOptions.services;
          in
          s.llmMode.enable || (!s.gufoStrix.enable && !s.radiance.enable);
        message = ''
          services.unholy uses both R9700s and the Strix Halo iGPU; run
          services.radiance / services.gufoStrix only under services.llmMode (which switches between them).
        '';
      }
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.lanExpose (
      lib.mapAttrsToList (_: inst: inst.port) cfg.instances
    );

    # Development runs need the GPUs: let the listed users stop and start the instances.
    security.polkit.extraConfig = lib.mkIf (cfg.managers != [ ]) ''
      polkit.addRule(function (action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            ${builtins.toJSON units}.indexOf(action.lookup("unit")) >= 0 &&
            ${builtins.toJSON cfg.managers}.indexOf(subject.user) >= 0) {
          return polkit.Result.YES;
        }
      });
    '';

    systemd.services = lib.mapAttrs' (
      name: inst:
      lib.nameValuePair (unitName name) {
        description = "unholy ${name} server (${inst.servedModelName})";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        conflicts = lib.remove "${unitName name}.service" units;

        environment = {
          HIP_VISIBLE_DEVICES = cfg.devices;
        }
        // inst.extraEnv;

        serviceConfig = {
          Type = "simple";
          ExecStart = "${unholy}/bin/unholy serve ${lib.concatStringsSep " " (serveArgs inst)}";
          # A GPU fault aborts the process; come back up (loading takes ~40 s). A stop by a manager
          # (systemctl stop) is not a failure and stays stopped.
          Restart = "always";
          RestartSec = 5;
          TimeoutStartSec = "10min";
          # SIGTERM stops the HTTP server and the engine; the weights are freed by process exit.
          TimeoutStopSec = 60;
          User = cfg.user;
          SupplementaryGroups = [
            "video"
            "render"
          ];
          # Pinned staging buffers and the APU's expert arena.
          LimitMEMLOCK = "infinity";
        };
      }
    ) cfg.instances;
  };
}
