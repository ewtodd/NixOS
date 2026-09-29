# gufo: Strix Halo (gfx1151) inference engine with continuous batching,
# chunked prefill and MTP speculative decoding. Runs on son-of-anton's iGPU.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.systemOptions.services.gufoStrix;
  gufo = inputs.gufo.packages.${pkgs.system}.default;

  # vLLM's warmup claims host memory; wait for its /health before loading,
  # bounded so a dead vLLM never blocks gufo.
  vllmCfg = config.systemOptions.services.vllm;
  vllmHealthWait = pkgs.writeShellScript "gufo-strix-wait-vllm" ''
    set -u
    url="http://127.0.0.1:${toString vllmCfg.port}/health"
    deadline=$(( $(${pkgs.coreutils}/bin/date +%s) + 300 ))
    while true; do
      if ${pkgs.curl}/bin/curl -fsS --max-time 5 "$url" >/dev/null 2>&1; then
        echo "vLLM /health is up; starting gufo-strix"
        exit 0
      fi
      if [ "$(${pkgs.coreutils}/bin/date +%s)" -ge "$deadline" ]; then
        echo "vLLM /health not up after 300s; starting gufo-strix anyway" >&2
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 5
    done
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
  ++ cfg.extraFlags;
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.lanExpose [ cfg.port ];

    systemd.services.gufo-strix = {
      description = "gufo Strix Halo inference server (${cfg.alias})";
      after = [ "network.target" ] ++ lib.optionals vllmCfg.enable [ "vllm.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HIP_VISIBLE_DEVICES = cfg.devices;
      }
      // cfg.extraEnv;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${gufo}/bin/gufo serve ${lib.concatStringsSep " " serverArgs}";
        ExecStartPre = lib.optionals vllmCfg.enable [ "${vllmHealthWait}" ];
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
