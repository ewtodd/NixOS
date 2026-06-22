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
    else
      inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.vulkan;

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

  # Dual-GPU host: pin each model to one Vulkan device so llama.cpp doesn't
  # split layers across both GPUs (APU models -> Vulkan1, eGPU -> Vulkan0).
  # Device order is PCI-bus-order deterministic under RADV; stable on this
  # headless server with scheduled reboots and a permanently attached eGPU.
  egpuPinning = cfg.backend == "vulkan" && cfg.egpu.enable;
  vkDevice = gpu: if gpu == "egpu" then "Vulkan0" else "Vulkan1";

  mkCmd =
    m:
    lib.concatStringsSep " " (
      [ "${llamaCpp}/bin/llama-server" ]
      ++ (if m.path != null then [ "-m ${m.path}" ] else [ "-hf ${m.hf}" ])
      ++ [
        "--n-gpu-layers 999"
        "--prio 1"
        "--no-mmap"
      ]
      # Pin to one Vulkan device so llama.cpp doesn't split across both GPUs.
      ++ lib.optional egpuPinning "--device ${vkDevice m.gpu}"
      ++ lib.optionals m.mlock [ "--mlock" ]
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
            # NOTE: no DRY/repetition sampler here on purpose. A context-wide
            # repetition penalty can't distinguish a stuck tool-loop from a
            # legitimate retry of the same command — both are the same token
            # sequence — so it forced models to corrupt commands (typos) just to
            # re-run them. Loop protection belongs at the harness layer (a hard
            # step cap like LibreChat's recursionLimit / qwen-code's max turns),
            # which aborts a runaway without mangling individual tool calls. Per-
            # model presence-penalty (set on the thinking models per their cards)
            # still handles ordinary prose repetition.
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
  # APU chat models are classified "big" (≥~100B-class; two won't fit in the
  # APU's unified RAM together) or "small" (all fit together), and embedding
  # model(s) are always resident (a RAG query embeds via bge-m3, then a chat
  # model generates — neither should evict the other). The APU policy, encoded
  # so every *maximal* valid set fits in memory by construction:
  #   * at most ONE big, optionally paired with at most ONE small   → lane A
  #   * OR any number of smalls together                            → lane B
  #   * AND the embedding model(s), always
  # This permits big+small and small+small (the real two-session cases) while
  # forbidding big+big and big+two-smalls (the combinations that OOM).
  #
  # The eGPU (R9700, 32 GB) is a SEPARATE memory pool. Models tagged gpu="egpu"
  # form their own lane: mutually exclusive among themselves (one dense ~30B
  # fills the card), but ANDed alongside the APU lanes so an eGPU model may
  # co-reside with any APU model. With no embedding model and ≤1 chat model
  # total the matrix is omitted (plain hot-swap).
  modelList = lib.imap0 (i: name: {
    inherit name;
    var = "m${toString i}";
  }) (lib.attrNames cfg.models);
  isEmbed = name: cfg.models.${name}.embedding;
  # "Resident" = always-loaded free riders: embedding models AND alwaysResident
  # chat models (e.g. the tiny title model). They're ANDed into every set and
  # ride alongside whatever chat model is loaded — including `solo` ones — so
  # they never participate in the chat lanes below.
  isResident = name: isEmbed name || cfg.models.${name}.alwaysResident;
  # eGPU-pinned chat models live in their own 32 GB pool, never in the APU
  # big/small/solo lanes (`big`/`solo` are ignored for them); they get their own
  # mutually-exclusive lane below.
  isEgpu = name: cfg.models.${name}.gpu == "egpu";
  isSolo = name: cfg.models.${name}.solo;
  # `solo` wins over `big`: a solo model is exclusive against every other chat
  # model, so it must not also appear in the big/small lanes.
  isBig = name: cfg.models.${name}.big && !isSolo name;
  # APU chat lanes exclude residents (always-on) and egpu models (separate pool).
  isApuChat = name: !isResident name && !isEgpu name;
  soloVars = map (e: e.var) (lib.filter (e: isApuChat e.name && isSolo e.name) modelList);
  bigVars = map (e: e.var) (lib.filter (e: isApuChat e.name && isBig e.name) modelList);
  smallVars = map (e: e.var) (
    lib.filter (e: isApuChat e.name && !isSolo e.name && !cfg.models.${e.name}.big) modelList
  );
  egpuVars = map (e: e.var) (lib.filter (e: !isResident e.name && isEgpu e.name) modelList);
  residentVars = map (e: e.var) (lib.filter (e: isResident e.name) modelList);
  chatVars = soloVars ++ bigVars ++ smallVars ++ egpuVars;
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
  # The big/small lanes (everything that isn't solo). Solo models are added as
  # their own top-level `|` alternatives below, so they're never co-resident with
  # any other chat model (subset semantics keep each solo valid on its own).
  nonSoloExpr =
    if laneA != "" && laneB != "" then
      "(${laneA}) | ${laneB}"
    else if laneA != "" then
      laneA
    else
      laneB; # may be "" when there are no non-solo chat models
  soloExpr = lib.concatStringsSep " | " soloVars;
  apuChatExpr =
    if soloExpr != "" && nonSoloExpr != "" then
      "${soloExpr} | ${nonSoloExpr}"
    else if soloExpr != "" then
      soloExpr
    else
      nonSoloExpr; # may be "" when there are no APU chat models
  # The eGPU pool: at most one egpu model resident at a time (32 GB fits ~one
  # dense ~30B). Subset semantics keep each valid alone, or none loaded.
  egpuExpr = lib.optionalString (egpuVars != [ ]) "(${lib.concatStringsSep " | " egpuVars})";
  # Independent memory pools are ANDed: any valid APU set may co-reside with any
  # eGPU choice. A single pool is left unwrapped (preserves single-GPU output).
  chatPools = lib.filter (e: e != "") [
    apuChatExpr
    egpuExpr
  ];
  chatExpr =
    if chatPools == [ ] then
      ""
    else if lib.length chatPools == 1 then
      lib.head chatPools
    else
      lib.concatMapStringsSep " & " (e: "(${e})") chatPools;
  residentAnd = lib.concatStringsSep " & " residentVars;
  matrixSet =
    if chatExpr == "" then
      residentAnd
    else if residentVars == [ ] then
      chatExpr
    else
      "(${chatExpr}) & ${residentAnd}";
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
      settings.matrix = lib.mkIf (residentVars != [ ] || lib.length chatVars > 1) {
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
