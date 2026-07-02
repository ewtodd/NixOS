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
      listenAddress = if cfg.lanExpose then "0.0.0.0" else "127.0.0.1";
      openFirewall = cfg.lanExpose;
      settings.healthCheckTimeout = 1200;
      settings.models = lib.mapAttrs (
        _name: m: { cmd = mkCmd m; } // lib.optionalAttrs (m.ttl != null) { inherit (m) ttl; }
      ) cfg.models;
      settings.matrix = lib.mkIf (residentVars != [ ] || lib.length chatVars > 1) {
        vars = matrixVars;
        sets.default = matrixSet;
      };
    };

    users.groups = lib.mkIf useCustomCache { llama-cache = { }; };
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
            { CacheDirectory = "llama-swap"; }
        )
        (lib.mkIf (cfg.backend == "cuda") { MemoryDenyWriteExecute = lib.mkForce false; })
      ];
    };
  };
}
