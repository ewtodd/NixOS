{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.systemOptions.services.radiance;

  # Built from source by radiance-nix against the TheRock ROCm 10.1 SDK unholy pins (the flake input follows
  # it), so both engines share one SDK in the store.
  radianceLib = inputs.radiance-nix.lib.${pkgs.stdenv.hostPlatform.system};
  spill = cfg.checkpointDir != null && cfg.diskCheckpoints > 0;
  radiance = radianceLib.mkRadiance {
    inherit pkgs;
    patches = lib.optional spill radianceLib.patches.checkpointSpill;
  };

  host = if cfg.lanExpose then "0.0.0.0" else "127.0.0.1";

  serveArgs = [
    "--model ${cfg.model}"
    "--host ${host}"
    "--port ${toString cfg.port}"
    "--served-model-name ${cfg.servedModelName}"
    "--tp ${toString cfg.tp}"
    "--max-model-len ${toString cfg.maxModelLen}"
    "--max-num-seqs ${toString cfg.maxNumSeqs}"
    "--kv-cache-dtype ${cfg.kvCacheDtype}"
  ]
  ++ lib.optionals (cfg.numSpeculativeTokens != null) [
    "--num-speculative-tokens ${toString cfg.numSpeculativeTokens}"
  ]
  ++ lib.optionals (cfg.maxNumBatchedTokens != null) [
    "--max-num-batched-tokens ${toString cfg.maxNumBatchedTokens}"
  ]
  ++ lib.optionals (cfg.ropeScaling != null) [ "--rope-scaling ${cfg.ropeScaling}" ]
  ++ lib.optionals (cfg.prefixCacheMib != null) [
    "--prefix-cache-mib ${toString cfg.prefixCacheMib}"
  ]
  ++ lib.optionals (cfg.checkpointSlots != null) [
    "--checkpoint-slots ${toString cfg.checkpointSlots}"
  ]
  ++ lib.optionals spill [
    "--checkpoint-dir ${cfg.checkpointDir}"
    "--disk-checkpoints ${toString cfg.diskCheckpoints}"
  ]
  ++ cfg.extraFlags;

  variantArgs =
    v:
    [
      "--model ${v.model}"
      "--host ${host}"
      "--port ${toString v.port}"
      "--served-model-name ${v.servedModelName}"
      "--tp ${toString v.tp}"
    ]
    ++ v.extraFlags;

  # Takes the served model name, the server's arguments and its extra environment; returns the systemd
  # service shared by radiance.service and every radiance-<variant>.service.
  mkService = servedModelName: args: extraEnv: {
    description = "Radiance inference server (${servedModelName})";
    after = [ "network.target" ];

    environment = {
      HIP_VISIBLE_DEVICES = cfg.devices;
    }
    // extraEnv;

    serviceConfig = {
      Type = "simple";
      ExecStart = "${radiance}/bin/radiance ${lib.concatStringsSep " " args}";
      # A GPU fault ends the process; come back up. A stop (systemctl stop, a Conflicts= from the
      # other mode) is not a failure and stays stopped.
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = "15min";
      # SIGTERM finishes the step in flight and releases the cards.
      TimeoutStopSec = 60;
      User = cfg.user;
      SupplementaryGroups = [
        "video"
        "render"
      ];
      # Pinned host memory (the KV/prefix tiers and the load window).
      LimitMEMLOCK = "infinity";
    };
  };

  variantUnits = lib.mapAttrsToList (name: _: "radiance-${name}.service") cfg.variants;
in
{
  config = lib.mkIf cfg.enable {
    systemOptions.firewall.allowFrom = lib.mkIf cfg.lanExpose (
      lib.genAttrs (map toString ([ cfg.port ] ++ lib.mapAttrsToList (_: v: v.port) cfg.variants)) (
        _: config.systemOptions.llmServerClients
      )
    );

    assertions = [
      {
        assertion = (cfg.checkpointDir != null) == (cfg.diskCheckpoints > 0);
        message = "services.radiance: checkpointDir and diskCheckpoints go together";
      }
    ];

    # The spill file lives on /work (the SATA array); the service user owns the directory.
    systemd.tmpfiles.rules = lib.optionals spill [
      "d ${cfg.checkpointDir} 0750 ${cfg.user} users - -"
    ];

    systemd.services = {
      radiance = mkService cfg.servedModelName serveArgs cfg.extraEnv // {
        unitConfig = lib.mkIf spill { RequiresMountsFor = [ cfg.checkpointDir ]; };
        wantedBy = [ "multi-user.target" ];
      };
    }
    // lib.mapAttrs' (
      name: v:
      lib.nameValuePair "radiance-${name}" (
        mkService v.servedModelName (variantArgs v) v.extraEnv
        // {
          conflicts = [ "radiance.service" ] ++ lib.remove "radiance-${name}.service" variantUnits;
        }
      )
    ) cfg.variants;
  };
}
