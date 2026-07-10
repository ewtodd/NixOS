{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.llamaSwap;

  llamaCpp =
    if cfg.backend == "cuda" then
      inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.cuda
    else if cfg.backend == "vulkan" then
      inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.vulkan
    else
      inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.rocm.overrideAttrs (
        finalAttrs: oldAttrs: {
          cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
            (pkgs.lib.cmakeFeature "CMAKE_HIP_FLAGS" "-funsafe-math-optimizations")
          ];
          postConfigure = (oldAttrs.postConfigure or "") + ''
            grep -q -- '-funsafe-math-optimizations' CMakeCache.txt
          '';

          postInstall = (oldAttrs.postInstall or "") + ''
            mkdir -p $out/nix-support
            echo "CMAKE_HIP_FLAGS=-funsafe-math-optimizations" > $out/nix-support/hip-flags
          '';
        }
      );

  vulkanIcd =
    if config.systemOptions.graphics.intel.enable then
      "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
    else
      "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";

  useCustomCache = cfg.cacheDir != null;
  cacheDir = if useCustomCache then cfg.cacheDir else "/var/cache/llama-swap";

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
      ++ [ (if m.mmap then "--mmap" else "--no-mmap") ]
      ++ lib.optionals m.mlock [ "--mlock" ]
      ++ (
        if m.embedding then
          [ "--embeddings" ]
        else
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
      ++ lib.optionals m.kvQuant [
        "--cache-type-k q8_0"
        "--cache-type-v q8_0"
      ]
      ++ lib.optional (m.mmproj != null) "--mmproj ${m.mmproj}"
      ++ m.extraFlags
      ++ [ "--host 0.0.0.0 --port \${PORT}" ]
    );

  modelList = lib.imap0 (i: name: {
    inherit name;
    var = "m${toString i}";
  }) (lib.attrNames cfg.models);

  isEmbed = name: cfg.models.${name}.embedding;

  isResident = name: isEmbed name || cfg.models.${name}.alwaysResident;

  isSolo = name: cfg.models.${name}.solo;

  isChat = name: !isResident name;

  soloNames = map (e: e.name) (lib.filter (e: isChat e.name && isSolo e.name) modelList);

  bigNames = map (e: e.name) (lib.filter (e: isChat e.name && cfg.models.${e.name}.big) modelList);

  smallNames = map (e: e.name) (
    lib.filter (e: isChat e.name && !isSolo e.name && !cfg.models.${e.name}.big) modelList
  );

  chatNames = soloNames ++ bigNames ++ smallNames;

  residentNames = map (e: e.name) (lib.filter (e: isResident e.name) modelList);
in
{
  config = lib.mkIf cfg.enable {
    assertions = lib.mapAttrsToList (name: m: {
      assertion = (m.path != null) != (m.hf != null);
      message = "systemOptions.services.llamaSwap.models.${name}: set exactly one of `path` or `hf`.";
    }) cfg.models;

    services.llama-swap = {
      enable = true;
      port = 8080;
      listenAddress = if cfg.lanExpose then "0.0.0.0" else "127.0.0.1";
      openFirewall = cfg.lanExpose;
      settings.healthCheckTimeout = 1200;

      settings.models = lib.mapAttrs (
        _name: m:
        {
          cmd = mkCmd m;
        }
        // lib.optionalAttrs (m.ttl != null) {
          inherit (m) ttl;
        }
      ) cfg.models;

      settings.groups = lib.mkIf (residentNames != [ ] || chatNames != [ ]) (
        lib.optionalAttrs (residentNames != [ ]) {
          resident = {
            persistent = true;
            exclusive = false;
            swap = false;
            members = residentNames;
          };
        }
        // lib.optionalAttrs (soloNames != [ ]) {
          solo = {
            exclusive = true;
            swap = true;
            members = soloNames;
          };
        }
        // lib.optionalAttrs (bigNames != [ ]) {
          big = {
            exclusive = false;
            swap = true;
            members = bigNames;
          };
        }
        // lib.optionalAttrs (smallNames != [ ]) {
          small = {
            exclusive = false;
            swap = true;
            members = smallNames;
          };
        }
      );

      settings.hooks = lib.mkIf (residentNames != [ ]) {
        on_startup.preload = residentNames;
      };
    };

    users.groups = lib.mkIf useCustomCache {
      llama-cache = { };
    };

    systemd.tmpfiles.rules = lib.mkIf useCustomCache [
      "d ${cfg.cacheDir} 2770 root llama-cache - -"
    ];

    systemd.services.llama-swap = {
      environment = lib.mkMerge [
        { LLAMA_CACHE = cacheDir; }
        (lib.mkIf (cfg.backend == "vulkan") {
          VK_ICD_FILENAMES = vulkanIcd;
          MESA_SHADER_CACHE_DIR = "${cacheDir}/mesa-shader-cache";
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
