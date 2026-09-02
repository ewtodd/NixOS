{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.systemOptions.services.ds4;

  ds4 = pkgs.callPackage ./pkgs/ds4.nix {
    src = inputs.ds4;
  };

  inherit (pkgs.rocmPackages)
    clr
    hipblas
    hipblaslt
    rocblas
    ;
  ldLibs = lib.concatStringsSep ":" (
    map (p: "${p}/lib") [
      clr
      hipblas
      hipblaslt
      rocblas
    ]
  );

  server = pkgs.writeShellScriptBin "ds4-server" ''
    export LD_LIBRARY_PATH=${ldLibs}:''${LD_LIBRARY_PATH:-}
    ${lib.optionalString (cfg.kvDiskDir != null) "mkdir -p ${cfg.kvDiskDir}"}
    exec ${ds4}/bin/ds4-server --model ${cfg.model} --dspark --mtp-model ${cfg.draftModel} --vision ${cfg.visionModel} --backend ${cfg.backend} --ctx ${toString cfg.ctxSize}  --tokens ${toString cfg.tokens} --threads ${toString cfg.threads} --power ${toString cfg.power} --prefill-chunk ${toString cfg.prefillChunk} --batched-session ${toString cfg.batchedSession} --host ${
      if cfg.lanExpose then "0.0.0.0" else "127.0.0.1"
    } --port ${toString cfg.port} ${
      lib.optionalString (
        cfg.kvDiskDir != null
      ) "--kv-disk-dir ${cfg.kvDiskDir} --kv-disk-space-mb ${toString cfg.kvDiskSpaceMb}"
    } ${lib.concatStringsSep " " cfg.extraFlags}
  '';
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.lanExpose [ cfg.port ];

    users.groups.llama-cache = { };

    systemd.tmpfiles.rules = lib.mkIf (cfg.kvDiskDir != null) [
      "d ${cfg.kvDiskDir} 0775 ${cfg.user} llama-cache - -"
    ];

    systemd.services.ds4 = {
      description = "antirez/ds4 DwarfStar DeepSeek-V4 server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment.HIP_VISIBLE_DEVICES = cfg.devices;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${server}/bin/ds4-server";
        Restart = "on-failure";
        RestartSec = 10;
        User = cfg.user;
        SupplementaryGroups = [
          "video"
          "render"
          "llama-cache"
        ];
        LimitMEMLOCK = "infinity";
        ReadWritePaths = lib.mkIf (cfg.kvDiskDir != null) [ "-${cfg.kvDiskDir}" ];
      };
    };
  };
}
