{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.systemOptions.services.gufoStrix;

  gufo = inputs.gufo.packages.${pkgs.system}.default.overrideAttrs (
    _: oldAttrs: {
      # YaRN above the native 262144 (gufo PR #350), and GUFO_GGUF_OVERLAY (cfg.overlays): tensors
      # replaced by name from extra GGUFs, e.g. the full-precision n-gram table.
      patches = (oldAttrs.patches or [ ]) ++ [
        ./gufo-pr350-yarn.diff
        ./gufo-gguf-overlay.diff
      ];
    }
  );

  nativeContext = 262144;

  radianceCfg = config.systemOptions.services.radiance;
  # The R9700 server sharing this host: gufo sizes its RAM snapshot budget from what is free when it
  # starts, and a server that starts later is not in that budget (gufo #556), so gufo waits for it.
  cardServer =
    if radianceCfg.enable then
      {
        name = "radiance";
        port = radianceCfg.port;
      }
    else
      null;
  cardServerWait = pkgs.writeShellScript "gufo-strix-wait-card-server" ''
    set -u
    url="http://127.0.0.1:${toString cardServer.port}/health"
    deadline=$(( $(${pkgs.coreutils}/bin/date +%s) + 600 ))
    while true; do
      if ${pkgs.curl}/bin/curl -fsS --max-time 5 "$url" >/dev/null 2>&1; then
        echo "${cardServer.name} /health is up; starting gufo-strix"
        exit 0
      fi
      if [ "$(${pkgs.coreutils}/bin/date +%s)" -ge "$deadline" ]; then
        echo "${cardServer.name} /health not up after 600s; starting gufo-strix anyway" >&2
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 5
    done
  '';

  # Freed GPU pages stay in the TTM page pool (ttm.page_pool_size is all of RAM on son-of-anton) and are not counted
  # in MemAvailable, so after unholy or another big GPU process has run, RAM reads ~10 GB available with nothing
  # loaded. gufo sizes its RAM snapshot cache from MemAvailable (half of it, explicit values capped at it minus
  # 4 GiB) and gets 2.7-3.7 GB instead of ~7: Flash-Next then serves 4 requests on 2 sessions at ~41 tok/s instead
  # of ~60. Dropping caches runs the pool's shrinker and returns those pages before gufo measures.
  releasePagePool = pkgs.writeShellScript "gufo-strix-release-page-pool" ''
    ${pkgs.coreutils}/bin/sync
    echo 3 > /proc/sys/vm/drop_caches
    ${pkgs.gnugrep}/bin/grep -E "^(MemAvailable|GPUReclaim)" /proc/meminfo
  '';

  serverArgs = [
    "--host ${if cfg.lanExpose then "0.0.0.0" else "127.0.0.1"}"
    "--port ${toString cfg.port}"
    "--sessions ${toString cfg.sessions}"
    "llm"
    "--model ${cfg.model}"
    "--context ${toString cfg.context}"
    "--served-model-name ${cfg.alias}"
  ]
  ++ lib.optionals (cfg.think != null) [ "--think ${cfg.think}" ]
  ++ lib.optionals (cfg.mtpModel != null) [
    "--speculative mtp"
    "--mtp-model ${cfg.mtpModel}"
    "--draft-tokens ${toString cfg.draftTokens}"
  ]
  ++ lib.optionals (cfg.mmproj != null) [ "--mmproj ${cfg.mmproj}" ]
  ++ lib.optionals (cfg.diskCacheDir != null) (
    [ "--cache-disk ${cfg.diskCacheDir}" ]
    ++ lib.optionals (cfg.diskCacheBytes != null) [
      "--cache-disk-bytes ${toString cfg.diskCacheBytes}"
    ]
  )
  ++ lib.optionals cfg.logProgress [ "--log-progress" ]
  ++ lib.optionals (cfg.logLevel != null) [ "--log-level ${cfg.logLevel}" ]
  ++ cfg.extraFlags;
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.yarn == null || cfg.yarn == (cfg.context > nativeContext);
        message = ''
          services.gufoStrix.yarn = ${toString cfg.yarn} contradicts
          context = ${toString cfg.context} (YaRN is active exactly above the
          native ${toString nativeContext} tokens).
        '';
      }
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.lanExpose [ cfg.port ];

    # serve auto-creates a missing cache directory, but InitializeDirectory
    # refuses one it does not own (st_uid == geteuid, then chmod 0700),
    # so the rule is a convenience, not a requirement; setgid keeps the
    # group shared with the other llama services.
    systemd.tmpfiles.rules = lib.optionals (cfg.diskCacheDir != null) [
      "d ${cfg.diskCacheDir} 2770 ${cfg.user} llama-cache - -"
    ];

    systemd.services.gufo-strix = {
      description = "gufo Strix Halo inference server (${cfg.alias})";
      after = [ "network.target" ] ++ lib.optionals (cardServer != null) [ "${cardServer.name}.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HIP_VISIBLE_DEVICES = cfg.devices;
      }
      // lib.optionalAttrs (cfg.overlays != [ ]) {
        GUFO_GGUF_OVERLAY = lib.concatStringsSep ":" cfg.overlays;
      }
      // cfg.extraEnv;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${gufo}/bin/gufo serve ${lib.concatStringsSep " " serverArgs}";
        # The card server first (it allocates first), then release the page pool as root ("+") so gufo's RAM
        # budget sees what is really free.
        ExecStartPre =
          lib.optionals (cardServer != null) [ "${cardServerWait}" ]
          ++ lib.optionals cfg.releaseGpuPagePool [ "+${releasePagePool}" ];
        Restart = "on-failure";
        RestartSec = 10;
        TimeoutStartSec = "30min";
        User = cfg.user;
        SupplementaryGroups = [
          "video"
          "render"
          "llama-cache"
        ];
        LimitMEMLOCK = "infinity";
      };
    };
  };
}
