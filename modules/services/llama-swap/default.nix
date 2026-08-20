{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.llamaSwap;
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
      finalAttrs: oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          mkdir -p $out/nix-support
          echo "${llamaCppVersion}" > $out/nix-support/llama-cpp-version
        '';
      }
    );

  rocm = (stampedLlama llamaPkgs.rocm).overrideAttrs (
    finalAttrs: oldAttrs: {
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
    finalAttrs: oldAttrs: {
      cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
        "-DCMAKE_CUDA_ARCHITECTURES=89"
      ];

      postInstall = (oldAttrs.postInstall or "") + ''
        mkdir -p $out/nix-support
        echo "CMAKE_CUDA_FLAGS=-DCMAKE_CUDA_ARCHITECTURES=89" > $out/nix-support/supported-hardware
      '';
    }
  );

  llamaCpp =
    if cfg.backend == "cuda" then
      cuda
    else if cfg.backend == "vulkan" then
      stampedLlama llamaPkgs.vulkan
    else
      rocm;
  # Mesa names ICD files by arch only (radeon_icd.x86_64.json), NOT by
  # system triple (radeon_icd.x86_64-linux.json) — a wrong path here makes
  # the Vulkan loader ignore VK_ICD_FILENAMES and enumerate every ICD on
  # the machine (iGPU, llvmpipe), so llama.cpp can bind the wrong device.
  arch = pkgs.stdenv.hostPlatform.parsed.cpu.name;
  vulkanIcd =
    if config.systemOptions.graphics.intel.enable then
      "/run/opengl-driver/share/vulkan/icd.d/intel_icd.${arch}.json"
    else if config.systemOptions.graphics.amd.enable then
      "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.${arch}.json"
    else if config.systemOptions.graphics.asahi.enable then
      "/run/opengl-driver/share/vulkan/icd.d/asahi_icd.${arch}.json"
    else
      "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.${arch}.json";

  useCustomCache = cfg.cacheDir != null;
  cacheDir = cfg.cacheDir;

  embedding = cfg.embeddingModel;

  embeddingCmd =
    if embedding == null then
      null
    else
      lib.concatStringsSep " " (
        [ "${llamaCpp}/bin/llama-server" ]
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
          "--ubatch-size 512"
          "--n-gpu-layers ${toString embedding.gpuLayers}"
          "--host 127.0.0.1 --port ${toString embedding.port}"
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
      ++ lib.optional (m.specType != "none") "--spec-type ngram-mod,${m.specType} --spec-draft-ngl all"
      ++ lib.optional (m.specType != "none") "--spec-draft-n-max ${toString m.specDraftNMax}"
      ++ lib.optional (m.specDraftModel != null) "--spec-draft-model ${m.specDraftModel}"
      ++ lib.optional (m.specDraftHf != null) "--spec-draft-hf ${m.specDraftHf}"
      ++ lib.optional (m.specDraftDevice != null) "--spec-draft-device ${m.specDraftDevice}"
      ++ m.extraFlags
      ++ [
        "--host 0.0.0.0 --port \${PORT}"
        "--no-webui"
      ]
      ++ lib.optionals cfg.verboseLogging [ "--verbose" ]
    );

  modelNames = lib.attrNames cfg.models;

  # llama-swap's matrix DSL can only reference models through short var ids
  # (alphanumeric, 1-8 chars in the pinned llama-swap), so every model gets
  # an id in definition order.
  modelList = lib.imap0 (i: name: {
    inherit name;
    var = "m${toString i}";
  }) modelNames;

  nameToVar = lib.listToAttrs (
    map (e: {
      name = e.name;
      value = e.var;
    }) modelList
  );

  isResident = name: cfg.models.${name}.alwaysResident;

  residentNames = builtins.filter isResident modelNames;

  # A comma list in `device` spans several devices, so such a model occupies
  # the whole host: it is solo.
  spansMultiDevice =
    name:
    let
      d = cfg.models.${name}.device;
    in
    d != null && builtins.match ".*,.*" d != null;

  isSolo = name: cfg.models.${name}.solo || spansMultiDevice name;

  soloNames = builtins.filter isSolo modelNames;

  # Remaining models are grouped by device: models on the same device are
  # alternatives (one resident per device at a time); models on distinct
  # devices may all be resident together.
  groupableNames = builtins.filter (n: !isResident n && !isSolo n) modelNames;

  deviceKey =
    name:
    let
      d = cfg.models.${name}.device;
    in
    if d == null then "unpinned:${name}" else d;

  deviceGroups = lib.groupBy deviceKey groupableNames;

  deviceKeys = lib.attrNames deviceGroups;

  powerset = xs: lib.foldl' (acc: x: acc ++ map (s: s ++ [ x ]) acc) [ [ ] ] xs;

  groupExpr =
    key: "(" + lib.concatStringsSep " | " (map (n: nameToVar.${n}) deviceGroups.${key}) + ")";

  subsetExpr = subset: lib.concatStringsSep " & " (map groupExpr subset);

  # every non-empty combination of devices may be resident together
  deviceSetExprs = map subsetExpr (builtins.filter (s: s != [ ]) (powerset deviceKeys));

  soloSetExprs = map (n: nameToVar.${n}) soloNames;

  residentSuffix =
    if residentNames == [ ] then
      ""
    else
      " & " + lib.concatStringsSep " & " (map (n: nameToVar.${n}) residentNames);

  withResidents = e: if residentSuffix == "" then e else "(${e})${residentSuffix}";

  setExprs = map withResidents (soloSetExprs ++ deviceSetExprs);

  # A residents-only host (e.g. oracle's router pair) would otherwise produce
  # an empty matrix, which llama-swap rejects: give it the resident set.
  matrixSetExprs =
    if setExprs != [ ] then
      setExprs
    else if residentNames != [ ] then
      [ (lib.concatStringsSep " & " (map (n: nameToVar.${n}) residentNames)) ]
    else
      [ ];

  preloadNames = lib.unique (
    residentNames ++ builtins.filter (n: cfg.models.${n}.preload) modelNames
  );
in
{
  config = lib.mkIf cfg.enable {
    assertions =
      lib.mapAttrsToList (name: m: {
        assertion = (m.path != null) != (m.hf != null);
        message = "systemOptions.services.llamaSwap.models.${name}: set exactly one of `path` or `hf`.";
      }) cfg.models
      ++ lib.mapAttrsToList (name: m: {
        assertion = !(m.specDraftModel != null && m.specDraftHf != null);
        message = "systemOptions.services.llamaSwap.models.${name}: set at most one of `specDraftModel` or `specDraftHf`.";
      }) cfg.models;

    services.llama-swap = {
      enable = true;
      port = cfg.port;
      listenAddress = if cfg.lanExpose then "0.0.0.0" else "127.0.0.1";
      openFirewall = cfg.lanExpose;
      settings.healthCheckTimeout = 1200;

      # Verbose mode (systemOptions.services.llamaSwap.verboseLogging): debug
      # log level, RFC3339 timestamps, and route llama-server output to stdout
      # so the journal captures it. Logs are otherwise only in llama-swap's
      # in-memory history (/logs, /logs/stream/...).
      settings.logLevel = lib.mkIf cfg.verboseLogging "debug";
      settings.logTimeFormat = lib.mkIf cfg.verboseLogging "rfc3339nano";
      settings.logToStdout = lib.mkIf cfg.verboseLogging "both";

      settings.models = lib.mapAttrs (
        _name: m:
        {
          cmd = mkCmd m;
        }
        // lib.optionalAttrs (m.ttl != null) {
          inherit (m) ttl;
        }
      ) cfg.models;

      # The swap matrix: models are referenced through short var ids (the
      # pinned llama-swap cannot use raw model names in expressions). Every
      # set is one allowed combination of co-resident models.
      settings.routing = lib.mkIf (modelNames != [ ]) {
        router = {
          use = "matrix";
          settings.matrix = {
            vars = lib.listToAttrs (
              map (e: {
                name = e.var;
                value = e.name;
              }) modelList
            );
            sets = lib.listToAttrs (
              lib.imap1 (i: expr: {
                name = "set${toString i}";
                value = expr;
              }) matrixSetExprs
            );
          };
        };
      };

      settings.hooks = lib.mkIf (preloadNames != [ ]) {
        on_startup.preload = preloadNames;
      };
    };

    users.groups = lib.mkIf useCustomCache {
      llama-cache = { };
    };

    systemd.tmpfiles.rules = lib.mkIf useCustomCache [
      "d ${cfg.cacheDir} 2770 root llama-cache - -"
    ];

    systemd.services.llama-embeddings = lib.mkIf (embeddingCmd != null) {
      description = "llama.cpp embedding server (always resident)";
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

    systemd.services.llama-swap = {
      environment = lib.mkMerge [
        { LLAMA_CACHE = lib.mkForce cacheDir; }
        (lib.mkIf (cfg.backend == "vulkan") {
          VK_ICD_FILENAMES = vulkanIcd;
          MESA_SHADER_CACHE_DIR = "${lib.toString cacheDir}/mesa-shader-cache";
        })
      ];

      serviceConfig = lib.mkMerge [
        {
          SupplementaryGroups = [
            "video"
            "render"
          ]
          ++ lib.optional useCustomCache "llama-cache";

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
              CacheDirectory = "llama-swap";
            }
        )
        (lib.mkIf (cfg.backend == "cuda") {
          MemoryDenyWriteExecute = lib.mkForce false;
        })
      ];
    };
  };
}
