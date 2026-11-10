{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.systemOptions.services.gufoStrix;

  # Upstream's package as is: the toolchain gufo qualifies (GCC 15.3, ROCm
  # 7.2.3) with its patched ROCr, which keeps queue memory resident during
  # host memory compaction on Strix Halo.
  gufo = inputs.gufo.packages.${pkgs.system}.default;
  # The same gufo rebuilt with the DeepSeek-V4.1 extension compiled in
  # (its flake overrides `extensions` on the `gufo` input it follows).
  gufoDeepseek = inputs.ds41-gufo-extension.packages.${pkgs.system}.default;
  deepseek = cfg.deepseek;

  nativeContext = 262144;

  radianceCfg = config.systemOptions.services.radiance;
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

  releasePagePool = pkgs.writeShellScript "gufo-strix-release-page-pool" ''
    ${pkgs.coreutils}/bin/sync
    echo 3 > /proc/sys/vm/drop_caches
    ${pkgs.gnugrep}/bin/grep -E "^(MemAvailable|GPUReclaim)" /proc/meminfo
  '';

  # The arguments every server here starts with; s holds port, sessions, model, context and alias.
  baseArgs = s: [
    "--host ${if cfg.lanExpose then "0.0.0.0" else "127.0.0.1"}"
    "--port ${toString s.port}"
    "--sessions ${toString s.sessions}"
    "llm"
    "--model ${s.model}"
    "--context ${toString s.context}"
    "--served-model-name ${s.alias}"
  ];

  deepseekArgs =
    baseArgs deepseek
    ++ [
      "--speculative dspark"
      "--dspark-model ${deepseek.dsparkModel}"
      "--stream-experts"
      "--expert-cache-bytes ${toString deepseek.expertCacheBytes}"
    ]
    ++ lib.optionals (deepseek.mmproj != null) [ "--mmproj ${deepseek.mmproj}" ]
    ++ deepseek.extraFlags;

  serverArgs =
    baseArgs cfg
    ++ lib.optionals (cfg.context > nativeContext) [ "--enable-yarn" ]
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
    ++ lib.optionals (cfg.cacheRamBytes != null) [
      "--cache-ram-bytes ${toString cfg.cacheRamBytes}"
    ]
    ++ lib.optionals cfg.logProgress [ "--log-progress" ]
    ++ lib.optionals (cfg.logLevel != null) [ "--log-level ${cfg.logLevel}" ]
    ++ cfg.extraFlags;

  # A systemd service for gufo serve on the iGPU, from its description, the gufo package and its arguments.
  mkUnit = description: package: args: {
    inherit description;
    after = [ "network.target" ] ++ lib.optionals (cardServer != null) [ "${cardServer.name}.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      HIP_VISIBLE_DEVICES = cfg.devices;
    }
    // cfg.extraEnv;

    serviceConfig = {
      Type = "simple";
      ExecStart = "${package}/bin/gufo serve ${lib.concatStringsSep " " args}";
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

    systemOptions.firewall.allowFrom = lib.mkIf cfg.lanExpose (
      lib.genAttrs (map toString ([ cfg.port ] ++ lib.optional deepseek.enable deepseek.port)) (
        _: config.systemOptions.llmServerClients
      )
    );

    # serve auto-creates a missing cache directory, but InitializeDirectory
    # refuses one it does not own (st_uid == geteuid, then chmod 0700),
    # so the rule is a convenience, not a requirement; setgid keeps the
    # group shared with the other llama services.
    systemd.tmpfiles.rules = lib.optionals (cfg.diskCacheDir != null) [
      "d ${cfg.diskCacheDir} 2770 ${cfg.user} llama-cache - -"
    ];

    systemd.services = {
      gufo-strix = mkUnit "gufo Strix Halo inference server (${cfg.alias})" gufo serverArgs;
    }
    // lib.optionalAttrs deepseek.enable {
      gufo-deepseek =
        mkUnit "gufo DeepSeek-V4.1-Flash server (${deepseek.alias})" gufoDeepseek deepseekArgs
        // {
          conflicts = [ "gufo-strix.service" ];
        };
    };
  };
}
