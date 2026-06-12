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

  # RADV ICD for the Vulkan backend (present via graphics.amd.enable).
  radvIcd = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";

  useCustomCache = cfg.cacheDir != null;
  cacheDir = if useCustomCache then cfg.cacheDir else "/var/cache/llama-swap";

  mkCmd =
    m:
    lib.concatStringsSep " " (
      [ "${llamaCpp}/bin/llama-server" ]
      ++ (if m.path != null then [ "-m ${m.path}" ] else [ "-hf ${m.hf}" ])
      ++ [
        "-ngl 999"
        "--jinja"
        "-fa on"
        "--ctx-size ${toString m.ctxSize}"
      ]
      ++ m.extraFlags
      ++ [ "--host 0.0.0.0 --port \${PORT}" ]
    );
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
      listenAddress = "0.0.0.0"; # LAN-bound so the LiteLLM proxy on mu can reach it
      openFirewall = true; # opens 8080 (inner host; no public port-forward on the router)
      settings.models = lib.mapAttrs (
        _name: m: { cmd = mkCmd m; } // lib.optionalAttrs (m.ttl != null) { inherit (m) ttl; }
      ) cfg.models;
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
        (lib.mkIf (cfg.backend == "vulkan") { VK_ICD_FILENAMES = radvIcd; })
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
