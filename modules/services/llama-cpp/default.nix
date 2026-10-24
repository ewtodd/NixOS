{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.llamaCpp;
  system = pkgs.stdenv.hostPlatform.system;
  llamaPkgs = inputs.llama-cpp.packages.${system};

  llamaCppVersion =
    let
      src = inputs.llama-cpp;
      date = src.lastModifiedDate or "unknown-date";
      rev = src.shortRev or (if src ? rev then builtins.substring 0 12 src.rev else "dirty");
    in
    "${date}-${rev}";

  versionedLlama =
    pkg:
    pkg.override {
      llamaVersion = llamaCppVersion;
    };

  stampedLlama =
    pkg:
    (versionedLlama pkg).overrideAttrs (
      _: oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          mkdir -p $out/nix-support
          echo "${llamaCppVersion}" > $out/nix-support/llama-cpp-version
        '';
      }
    );

  rocm = (stampedLlama llamaPkgs.rocm).overrideAttrs (
    _: oldAttrs: {
      cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
        (pkgs.lib.cmakeFeature "CMAKE_HIP_ARCHITECTURES" "gfx1151;gfx1201")
        "-DGPU_TARGETS=gfx1151;gfx1201"
      ];

      postInstall = (oldAttrs.postInstall or "") + ''
        mkdir -p $out/nix-support
        echo "-DGPU_TARGETS=gfx1151,gfx1201" > $out/nix-support/supported-hardware 
      '';
    }
  );

  cuda = (stampedLlama llamaPkgs.cuda).overrideAttrs (
    _: oldAttrs: {
      cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
        "-DCMAKE_CUDA_ARCHITECTURES=89"
      ];

      postInstall = (oldAttrs.postInstall or "") + ''
        mkdir -p $out/nix-support
        echo "CMAKE_CUDA_FLAGS=-DCMAKE_CUDA_ARCHITECTURES=89" > $out/nix-support/supported-hardware
      '';
    }
  );

  llamaFor =
    backend:
    if backend == "cuda" then
      cuda
    else if backend == "vulkan" then
      stampedLlama llamaPkgs.vulkan
    else if backend == "cpu" then
      stampedLlama llamaPkgs.default
    else
      rocm;
  llamaCpp = llamaFor cfg.backend;
  # Mesa names ICD files by arch only (radeon_icd.x86_64.json), NOT by
  # system triple (radeon_icd.x86_64-linux.json) — a wrong path here makes
  # the Vulkan loader ignore VK_ICD_FILENAMES and enumerate every ICD on
  # the machine (iGPU, llvmpipe), so llama.cpp can bind the wrong device.
  arch = pkgs.stdenv.hostPlatform.parsed.cpu.name;
  vulkanDriver =
    if cfg.vulkanDriver != null then
      cfg.vulkanDriver
    else if config.systemOptions.graphics.intel.enable then
      "intel"
    else if config.systemOptions.graphics.amd.enable then
      "radeon"
    else if config.systemOptions.graphics.asahi.enable then
      "asahi"
    else
      "radeon";
  vulkanIcd = "/run/opengl-driver/share/vulkan/icd.d/${vulkanDriver}_icd.${arch}.json";

  useCustomCache = cfg.cacheDir != null;
  cacheDir = cfg.cacheDir;

  embedding = cfg.embeddingModel;
  embeddingBackend =
    if embedding != null && embedding.backend != null then embedding.backend else cfg.backend;

  usesVulkan =
    (modelNames != [ ] && cfg.backend == "vulkan")
    || (embedding != null && embeddingBackend == "vulkan");

  embeddingCmd =
    if embedding == null then
      null
    else
      lib.concatStringsSep " " (
        [ "${llamaFor embeddingBackend}/bin/llama-server" ]
        ++ (
          if embedding.path != null then
            [ "-m ${embedding.path}" ]
          else
            [ "-hf ${embedding.hf}" ]
            ++ lib.optionals (embedding.hfFile != null) [ "--hf-file ${embedding.hfFile}" ]
        )
        ++ [
          "--embedding"
          "--pooling ${embedding.pooling}"
          "--ctx-size ${toString embedding.ctxSize}"
          "--batch-size 2048"
          "--ubatch-size 2048"
          "--n-gpu-layers ${toString embedding.gpuLayers}"
          "--parallel 1"
          "--host ${if cfg.lanExpose then "0.0.0.0" else "127.0.0.1"}"
          "--port ${toString embedding.port}"
          "--no-webui"
        ]
        ++ lib.optionals cfg.verboseLogging [ "--verbose" ]
      );

  mkCmd =
    m:
    lib.concatStringsSep " " (
      [ "${llamaCpp}/bin/llama-server" ]
      ++ (
        if m.path != null then
          [ "-m ${m.path}" ]
        else
          [ "-hf ${m.hf}" ] ++ lib.optionals (m.hfFile != null) [ "--hf-file ${m.hfFile}" ]
      )
      ++ [
        "--n-gpu-layers ${m.gpuLayers}"
        "--prio 1"
      ]
      ++ lib.optional (m.device != null) "--device ${m.device}"
      ++ lib.optional (m.splitMode != null) "--split-mode ${m.splitMode}"
      ++ lib.optional (m.tensorSplit != null) "--tensor-split ${m.tensorSplit}"
      ++ lib.optionals (m.loadMode != "none") [ "--load-mode ${m.loadMode}" ]
      ++ (
        [
          "--jinja"
          "--flash-attn ${m.flashAttn}"
          "--batch-size ${toString m.batchSize}"
          "--ubatch-size ${toString m.ubatchSize}"
        ]
        ++ lib.optionals (m.cacheReuse != null) [
          "--cache-reuse ${toString m.cacheReuse}"
        ]
        ++ lib.optionals (m.cacheRam != null) [
          "--cache-ram ${toString m.cacheRam}"
        ]
        ++ lib.optionals (m.ctxCheckpoints != null) [
          "--ctx-checkpoints ${toString m.ctxCheckpoints}"
        ]
        ++ lib.optionals (m.checkpointMinStep != null) [
          "--checkpoint-min-step ${toString m.checkpointMinStep}"
        ]
      )
      ++ [ "--ctx-size ${toString m.ctxSize}" ]
      ++ lib.optionals (m.parallel != null) [ "--parallel ${toString m.parallel}" ]
      ++ lib.optionals (m.nCpuMoe != null) [ "--n-cpu-moe ${toString m.nCpuMoe}" ]
      ++ lib.optionals (m.chatTemplateFile != null) [ "--chat-template-file ${m.chatTemplateFile}" ]
      ++ lib.optionals m.noWarmup [ "--no-warmup" ]
      ++ lib.optionals m.noRepack [ "--no-repack" ]
      ++ lib.optionals m.reasoningPreserve [ "--reasoning-preserve" ]
      ++ [
        "--cache-type-k ${m.kQuant}"
        "--cache-type-v ${m.vQuant}"
      ]
      ++ lib.optional (m.mmproj != null) "--mmproj ${m.mmproj}"
      ++ lib.optional (m.mmprojDevice != null) "--mmproj-device ${m.mmprojDevice}"
      ++ lib.optional (m.specType != "none") "--spec-type ${m.specType} --spec-draft-ngl all"
      ++ lib.optional (m.specType != "none") "--spec-draft-n-max ${toString m.specDraftNMax}"
      ++ lib.optional (m.specDraftModel != null) "--spec-draft-model ${m.specDraftModel}"
      ++ lib.optional (m.specDraftHf != null) "--spec-draft-hf ${m.specDraftHf}"
      ++ lib.optional (m.specDraftDevice != null) "--spec-draft-device ${m.specDraftDevice}"
      ++ m.extraFlags
      ++ [
        "--host ${if cfg.lanExpose then "0.0.0.0" else "127.0.0.1"}"
        "--port ${toString m.port}"
        "--no-webui"
      ]
      ++ lib.optionals cfg.verboseLogging [ "--verbose" ]
    );

  modelNames = lib.attrNames cfg.models;

  # One always-on llama-server per model, each on its own port.
  modelServices = lib.listToAttrs (
    map (name: {
      name = "llama-server-${name}";
      value =
        let
          m = cfg.models.${name};
        in
        {
          description = "llama.cpp server for ${name}";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          serviceConfig = lib.mkMerge [
            {
              Type = "simple";
              ExecStart = mkCmd m;
              Restart = "on-failure";
              RestartSec = "5s";

              SupplementaryGroups = [
                "video"
                "render"
              ]
              ++ lib.optionals useCustomCache [ "llama-cache" ];

              LimitMEMLOCK = "infinity";
            }
            (
              if useCustomCache then
                {
                  ReadWritePaths = [ cfg.cacheDir ];
                  UMask = "0002";
                }
              else
                {
                  CacheDirectory = "llama-${name}";
                }
            )
            (lib.mkIf (cfg.backend == "cuda") {
              MemoryDenyWriteExecute = lib.mkForce false;
            })
          ];

          environment = lib.mkMerge [
            { LLAMA_CACHE = lib.mkForce cacheDir; }
            (lib.mkIf (cfg.backend == "vulkan") {
              VK_ICD_FILENAMES = vulkanIcd;
              MESA_SHADER_CACHE_DIR = "${lib.toString cacheDir}/mesa-shader-cache";
            })
          ];
        };
    }) modelNames
  );
in
{
  config = lib.mkIf cfg.enable {
    assertions =
      lib.mapAttrsToList (name: m: {
        assertion = (m.path != null) != (m.hf != null);
        message = "systemOptions.services.llamaCpp.models.${name}: set exactly one of `path` or `hf`.";
      }) cfg.models
      ++ lib.mapAttrsToList (name: m: {
        assertion = !(m.specDraftModel != null && m.specDraftHf != null);
        message = "systemOptions.services.llamaCpp.models.${name}: set at most one of `specDraftModel` or `specDraftHf`.";
      }) cfg.models
      ++ lib.optional (modelNames != [ ]) {
        assertion =
          let
            ports = map (name: cfg.models.${name}.port) modelNames;
          in
          lib.unique ports == ports;
        message = "systemOptions.services.llamaCpp.models: every model needs a distinct `port`.";
      };

    # The Vulkan backend loads Mesa's ICDs from /run/opengl-driver.
    hardware.graphics.enable = lib.mkIf usesVulkan true;

    users.groups.llama-cache = lib.mkIf useCustomCache { };
    systemd.tmpfiles.rules = lib.mkIf useCustomCache [
      "d ${cfg.cacheDir} 2770 root llama-cache - -"
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.lanExpose (
      map (name: cfg.models.${name}.port) modelNames ++ lib.optional (embedding != null) embedding.port
    );

    systemd.services = lib.mkMerge [
      (lib.mkIf (embeddingCmd != null) {
        llama-embeddings = {
          description = "llama.cpp embedding server";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          serviceConfig = lib.mkMerge [
            {
              Type = "simple";
              ExecStart = embeddingCmd;
              Restart = "on-failure";
              RestartSec = "5s";

              SupplementaryGroups = [
                "video"
                "render"
              ]
              ++ lib.optionals useCustomCache [ "llama-cache" ];

              LimitMEMLOCK = "infinity";
            }
            (
              if useCustomCache then
                {
                  ReadWritePaths = [ cfg.cacheDir ];
                  UMask = "0002";
                }
              else
                {
                  CacheDirectory = "llama-embeddings";
                }
            )
            (lib.mkIf (embeddingBackend == "cuda") {
              MemoryDenyWriteExecute = lib.mkForce false;
            })
          ];

          environment = lib.mkMerge [
            { LLAMA_CACHE = lib.mkForce cacheDir; }
            (lib.mkIf (embeddingBackend == "vulkan") {
              VK_ICD_FILENAMES = vulkanIcd;
              MESA_SHADER_CACHE_DIR = "${lib.toString cacheDir}/mesa-shader-cache";
            })
          ];
        };
      })
      modelServices
    ];
  };
}
