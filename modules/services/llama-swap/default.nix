{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.llamaSwap;

  llamaCpp =
    if cfg.backend == "cuda" then
      pkgs.llama-cpp.override { cudaSupport = true; }
    else
      pkgs.llama-cpp.override { vulkanSupport = true; };

  # Mesa Vulkan ICD for the vulkan backend, matched to the host's GPU: Intel
  # ANV on the iGPU laptops, RADV on the AMD boxes (the default). Both files
  # ship in mesa under /run/opengl-driver via hardware.graphics.
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
      ++ (if m.path != null then [ "-m ${m.path}" ] else [ "-hf ${m.hf}" ])
      ++ [ "-ngl 999" ]
      # --jinja (chat template) and -fa (flash attention) are generative-only and
      # break non-causal encoder embedding models; --embeddings turns on the
      # /v1/embeddings endpoint instead.
      ++ (
        if m.embedding then
          [ "--embeddings" ]
        else
          [
            "--jinja"
            "-fa on"
          ]
      )
      ++ [ "--ctx-size ${toString m.ctxSize}" ]
      # Vision projector (Qwen3-VL etc.): -hf doesn't auto-pull it for every
      # repo, so we point at an explicitly-fetched mmproj GGUF when set.
      ++ lib.optional (m.mmproj != null) "--mmproj ${m.mmproj}"
      ++ m.extraFlags
      ++ [ "--host 0.0.0.0 --port \${PORT}" ]
    );

  # llama-swap's `matrix` solver lets models run concurrently. We only need it
  # when there's an embedding model: a RAG query embeds (bge-m3) and then the
  # chat model generates, and we must not evict the (huge, slow-to-load) chat
  # model to load the tiny embedder, or vice-versa. The generated set allows any
  # single chat model to coexist with the embedding model(s); subset semantics
  # keep "chat alone" and "embed alone" valid, and two chat models still never
  # co-run. Without an embedding model the matrix is omitted (plain swap).
  modelList = lib.imap0 (i: name: {
    inherit name;
    var = "m${toString i}";
  }) (lib.attrNames cfg.models);
  isEmbed = name: cfg.models.${name}.embedding;
  chatVars = map (e: e.var) (lib.filter (e: !isEmbed e.name) modelList);
  embedVars = map (e: e.var) (lib.filter (e: isEmbed e.name) modelList);
  matrixVars = lib.listToAttrs (map (e: lib.nameValuePair e.var e.name) modelList);
  matrixSet =
    let
      embedExpr = lib.concatStringsSep " & " embedVars;
    in
    if chatVars == [ ] then embedExpr else "(${lib.concatStringsSep " | " chatVars}) & ${embedExpr}";
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
      # Localhost-only by default (local nvim FIM); lanExpose hosts (son-of-anton)
      # bind 0.0.0.0 and open 8080 so the LiteLLM proxy on mu can reach them.
      listenAddress = if cfg.lanExpose then "0.0.0.0" else "127.0.0.1";
      openFirewall = cfg.lanExpose;
      # Large-ctx warmups (shader compile + empty run) can exceed the 120s
      # default, and llama-swap kills the server mid-load when they do.
      settings.healthCheckTimeout = 600;
      settings.models = lib.mapAttrs (
        _name: m: { cmd = mkCmd m; } // lib.optionalAttrs (m.ttl != null) { inherit (m) ttl; }
      ) cfg.models;
      settings.matrix = lib.mkIf (embedVars != [ ]) {
        vars = matrixVars;
        sets.default = matrixSet;
      };
    };

    # Custom cache dir: a shared group lets the unit's transient DynamicUser
    # write across restarts; setgid + UMask 0002 keep new files group-writable.
    users.groups = lib.mkIf useCustomCache { llama-cache = { }; };
    systemd.tmpfiles.rules = lib.mkIf useCustomCache [
      "d ${cfg.cacheDir} 2770 root llama-cache - -"
    ];

    # The native unit is heavily sandboxed and grants neither GPU access nor a
    # writable cache. We add: GPU device groups; a persistent -hf download cache
    # (PrivateTmp would otherwise re-download every restart); the RADV ICD for
    # Vulkan; and, for CUDA, we drop MemoryDenyWriteExecute because the NVIDIA
    # driver JITs kernels into writable+executable memory and fails under it.
    systemd.services.llama-swap = {
      environment = lib.mkMerge [
        { LLAMA_CACHE = cacheDir; }
        (lib.mkIf (cfg.backend == "vulkan") {
          VK_ICD_FILENAMES = vulkanIcd;
          # The unit has no writable HOME, so Mesa disables its shader cache and
          # RADV recompiles every pipeline on each model load.
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
        }
        (
          if useCustomCache then
            {
              ReadWritePaths = [ cfg.cacheDir ];
              UMask = "0002";
            }
          else
            { CacheDirectory = "llama-swap"; }
        )
        (lib.mkIf (cfg.backend == "cuda") { MemoryDenyWriteExecute = lib.mkForce false; })
      ];
    };
  };
}
