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
    exec ${ds4}/bin/ds4-server \
      -m ${cfg.model} \
      --backend ${cfg.backend} \
      --ctx ${toString cfg.ctxSize} \
      --tokens ${toString cfg.tokens} \
      --threads ${toString cfg.threads} \
      --power ${toString cfg.power} \
      --prefill-chunk ${toString cfg.prefillChunk} \
      --batched-session ${toString cfg.batchedSession} \
      --host ${if cfg.lanExpose then "0.0.0.0" else "127.0.0.1"} \
      --port ${toString cfg.port} \
      ${
        lib.optionalString (
          cfg.kvDiskDir != null
        ) "--kv-disk-dir ${cfg.kvDiskDir} --kv-disk-space-mb ${toString cfg.kvDiskSpaceMb}"
      } \
      ${lib.concatStringsSep " " cfg.extraFlags}
  '';
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.lanExpose [ cfg.port ];

    # ds4 reads its GGUF from the shared llama-cache tree and writes its
    # checkpoint dir alongside it, so it needs the group the llama-swap module
    # provisions. Define it here (as llama-swap does) so it exists even when
    # llama-swap is disabled on the host.
    users.groups.llama-cache = { };

    systemd.tmpfiles.rules = lib.mkIf (cfg.kvDiskDir != null) [
      "d ${cfg.kvDiskDir} 0775 ${cfg.user} llama-cache - -"
    ];

    systemd.services.ds4 = {
      description = "antirez/ds4 DwarfStar DeepSeek-V4 server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      # Pin ds4 to the Strix Halo iGPU. ds4 has no device flag and uses HIP
      # device 0; without masking, device 0 is an R9700 (gfx1201), which the
      # gfx1151-only binary cannot run. HIP_VISIBLE_DEVICES=2 remaps the iGPU
      # to device 0 for ds4. The R9700s (0,1) stay reserved for vLLM.
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
        # ReadWritePaths is resolved during mount-namespace setup, which is
        # BEFORE Directory= creates the path (and tmpfiles can miss the dir on
        # a switch). Give it a "-" prefix so a not-yet-existing dir is ignored
        # rather than aborting at NAMESPACE; the wrapper mkdir's it first.
        ReadWritePaths = lib.mkIf (cfg.kvDiskDir != null) [ "-${cfg.kvDiskDir}" ];
      };
    };
  };
}
