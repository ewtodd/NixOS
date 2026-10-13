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

  serveArgs = [
    "--model ${cfg.model}"
    "--host ${if cfg.lanExpose then "0.0.0.0" else "127.0.0.1"}"
    "--port ${toString cfg.port}"
    "--served-model-name ${cfg.servedModelName}"
    "--kv-tokens ${toString cfg.kvTokens}"
    "--max-model-len ${toString cfg.maxModelLen}"
    "--max-num-seqs ${toString cfg.maxNumSeqs}"
    "--max-batch-tokens ${toString cfg.maxBatchTokens}"
    "--prefix-snapshots ${toString cfg.prefixSnapshots}"
    "--spec-drafts ${toString cfg.specDrafts}"
  ]
  ++ lib.optionals (cfg.exl3 != null) [ "--exl3 ${cfg.exl3}" ]
  ++ lib.optionals (cfg.profile != null) [ "--profile ${cfg.profile}" ]
  ++ cfg.extraFlags;
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

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.lanExpose [ cfg.port ];

    # Development runs need the GPUs: let the listed users stop and start the service.
    security.polkit.extraConfig = lib.mkIf (cfg.managers != [ ]) ''
      polkit.addRule(function (action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "unholy.service" &&
            ${builtins.toJSON cfg.managers}.indexOf(subject.user) >= 0) {
          return polkit.Result.YES;
        }
      });
    '';

    systemd.services.unholy = {
      description = "unholy DeepSeek-V4-Flash server (${cfg.servedModelName})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HIP_VISIBLE_DEVICES = cfg.devices;
      }
      // cfg.extraEnv;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${unholy}/bin/unholy serve ${lib.concatStringsSep " " serveArgs}";
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
    };
  };
}
