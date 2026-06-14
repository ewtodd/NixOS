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
      ++ [
        "--n-gpu-layers 999"
        "--prio 1"
        "--no-mmap"
        "--mlock"
      ]
      # --jinja (chat template) and -fa (flash attention) are generative-only and
      # break non-causal encoder embedding models; --embeddings turns on the
      # /v1/embeddings endpoint instead.
      ++ (
        if m.embedding then
          [ "--embeddings" ]
        else
          [
            "--jinja"
            "--flash-attn auto"
            "--batch-size 2048"
            "--ubatch-size 2048"
            "--cache-reuse 256"
          ]
      )
      ++ [ "--ctx-size ${toString m.ctxSize}" ]
      # Halve KV memory (q8_0 K and V); needs flash attention, on for chat.
      # (We leave --parallel at llama.cpp's auto, which gives a unified KV cache
      # serving several concurrent sessions at the FULL ctxSize each, for the
      # same KV memory as one session — so no slot flag is needed here.)
      ++ lib.optionals m.kvQuant [
        "--cache-type-k q8_0"
        "--cache-type-v q8_0"
      ]
      # Vision projector (Qwen3-VL etc.): -hf doesn't auto-pull it for every
      # repo, so we point at an explicitly-fetched mmproj GGUF when set.
      ++ lib.optional (m.mmproj != null) "--mmproj ${m.mmproj}"
      ++ m.extraFlags
      ++ [ "--host 0.0.0.0 --port \${PORT}" ]
    );

  # llama-swap's `matrix` solver decides which models may be resident together.
  # Its DSL: `&` = co-run, `|` = mutually exclusive alternatives, `()` groups,
  # and subset semantics — any subset of a declared set is also valid, and only
  # the requested models are actually started (nothing is preloaded).
  #
  # We classify chat models as "big" (≥~100B-class; two won't fit in unified RAM
  # together) or "small" (all fit together), and always keep the embedding
  # model(s) resident (a RAG query embeds via bge-m3, then a chat model
  # generates — neither should evict the other). The policy, encoded so that
  # every *maximal* valid set fits in memory by construction:
  #   * at most ONE big, optionally paired with at most ONE small   → lane A
  #   * OR any number of smalls together                            → lane B
  #   * AND the embedding model(s), always
  # This permits big+small and small+small (the real two-session cases) while
  # forbidding big+big and big+two-smalls (the combinations that OOM). With no
  # embedding model and ≤1 chat model the matrix is omitted (plain hot-swap).
  modelList = lib.imap0 (i: name: {
    inherit name;
    var = "m${toString i}";
  }) (lib.attrNames cfg.models);
  isEmbed = name: cfg.models.${name}.embedding;
  isBig = name: cfg.models.${name}.big;
  bigVars = map (e: e.var) (lib.filter (e: !isEmbed e.name && isBig e.name) modelList);
  smallVars = map (e: e.var) (lib.filter (e: !isEmbed e.name && !isBig e.name) modelList);
  embedVars = map (e: e.var) (lib.filter (e: isEmbed e.name) modelList);
  chatVars = bigVars ++ smallVars;
  matrixVars = lib.listToAttrs (map (e: lib.nameValuePair e.var e.name) modelList);

  bigExpr = lib.optionalString (bigVars != [ ]) "(${lib.concatStringsSep " | " bigVars})";
  smallOr = lib.optionalString (smallVars != [ ]) "(${lib.concatStringsSep " | " smallVars})";
  smallAnd = lib.optionalString (smallVars != [ ]) "(${lib.concatStringsSep " & " smallVars})";
  # lane A: one big (+ optionally one small); lane B: all smalls co-resident.
  laneA =
    if bigVars != [ ] && smallVars != [ ] then
      "${bigExpr} & ${smallOr}"
    else if bigVars != [ ] then
      bigExpr
    else
      "";
  laneB = smallAnd;
  chatExpr =
    if laneA != "" && laneB != "" then
      "(${laneA}) | ${laneB}"
    else if laneA != "" then
      laneA
    else
      laneB; # may be "" when there are no chat models at all
  embedAnd = lib.concatStringsSep " & " embedVars;
  matrixSet =
    if chatExpr == "" then
      embedAnd
    else if embedVars == [ ] then
      chatExpr
    else
      "(${chatExpr}) & ${embedAnd}";
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
      settings.matrix = lib.mkIf (embedVars != [ ] || lib.length chatVars > 1) {
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
