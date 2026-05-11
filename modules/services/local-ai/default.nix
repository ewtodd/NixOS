{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  cfg = config.services.localAI;
  enabled = config.systemOptions.services.localAI.enable;

  mkLlamaService =
    {
      tier,
      tierCfg,
    }:
    let
      modelPath = "${cfg.modelDir}/${tierCfg.modelFile}";
      args =
        [
          "--host"
          tierCfg.host
          "--port"
          (toString tierCfg.port)
          "--model"
          modelPath
          "--ctx-size"
          (toString tierCfg.contextSize)
          "--n-gpu-layers"
          (toString tierCfg.gpuLayers)
          "--alias"
          "llama-${tier}"
        ]
        ++ lib.optionals tierCfg.flashAttn [ "--flash-attn" ]
        ++ lib.optionals (tierCfg.nCpuMoe != null) [
          "--n-cpu-moe"
          (toString tierCfg.nCpuMoe)
        ]
        ++ tierCfg.extraArgs;
    in
    {
      description = "llama.cpp ${tier} inference server";
      after = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        DynamicUser = true;
        SupplementaryGroups = [ cfg.group ];
        CacheDirectory = "llama-${tier}";
        Environment = [ "LLAMA_CACHE=/var/cache/llama-${tier}" ];
        ExecStart = "${cfg.package}/bin/llama-server ${utils.escapeSystemdExecArgs args}";

        Restart = "no";
        KillSignal = "SIGINT";
        TimeoutStopSec = 30;

        PrivateDevices = false;
        DeviceAllow = [
          "/dev/nvidia0 rw"
          "/dev/nvidiactl rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-uvm-tools rw"
          "/dev/nvidia-modeset rw"
        ];

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        LockPersonality = true;
        CapabilityBoundingSet = "";
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
      };
    };

  aiderConfYml = pkgs.writeText "aider.conf.yml" ''
    model-settings-file: /etc/aider/aider.model.settings.yml
    model: openai/llama-foreground
    editor-model: openai/llama-background
    weak-model: openai/llama-foreground
    openai-api-key: dummy-not-used-for-local
    auto-commits: false
    gitignore: false
  '';

  aiderModelSettingsYml = pkgs.writeText "aider.model.settings.yml" ''
    - name: openai/llama-foreground
      edit_format: diff
      use_repo_map: true
      extra_params:
        api_base: http://localhost:${toString cfg.foreground.port}/v1
    - name: openai/llama-background
      edit_format: diff
      use_repo_map: true
      extra_params:
        api_base: http://localhost:${toString cfg.background.port}/v1
  '';
in
{
  options.services.localAI = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp.override {
        cudaSupport = true;
        cudaPackages = pkgs.cudaPackages;
      };
      defaultText = lib.literalExpression ''
        pkgs.llama-cpp.override { cudaSupport = true; cudaPackages = pkgs.cudaPackages; }
      '';
      description = "llama-cpp package. Defaults to a CUDA-enabled build.";
    };

    modelDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/llama/models";
      description = "Directory holding GGUF model files. Drop files here manually.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "llama";
      description = "Group that owns the model directory and can drop files in.";
    };

    openTailscale = lib.mkEnableOption "expose llama-server ports on tailscale0";

    foreground = {
      enable = lib.mkEnableOption "foreground (fast, GPU-resident) llama-server";
      modelFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "qwen3-30b-a3b-q5_k_xl.gguf";
        description = "GGUF filename relative to modelDir.";
      };
      host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8081;
      };
      contextSize = lib.mkOption {
        type = lib.types.int;
        default = 131072;
      };
      gpuLayers = lib.mkOption {
        type = lib.types.int;
        default = 999;
      };
      flashAttn = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Pass --flash-attn. If your llama.cpp expects --flash-attn on/off/auto, set this false and add the explicit form to extraArgs.";
      };
      nCpuMoe = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "If set, --n-cpu-moe N. Foreground tier defaults to fully-on-GPU.";
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };

    background = {
      enable = lib.mkEnableOption "background (hybrid CPU/GPU MoE) llama-server";
      modelFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "qwen3-235b-a22b-q4_k_xl.gguf";
        description = "GGUF filename relative to modelDir.";
      };
      host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8082;
      };
      contextSize = lib.mkOption {
        type = lib.types.int;
        default = 65536;
      };
      gpuLayers = lib.mkOption {
        type = lib.types.int;
        default = 999;
      };
      flashAttn = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      nCpuMoe = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Number of MoE layers to keep in CPU/RAM. Set to a positive int to enable expert offloading.";
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };

  config = lib.mkIf enabled (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.foreground.enable || cfg.foreground.modelFile != null;
          message = "services.localAI.foreground.modelFile must be set when foreground.enable = true";
        }
        {
          assertion = !cfg.background.enable || cfg.background.modelFile != null;
          message = "services.localAI.background.modelFile must be set when background.enable = true";
        }
      ];

      users.groups.${cfg.group} = { };

      systemd.tmpfiles.rules = [
        "d /var/lib/llama 0755 root ${cfg.group} -"
        "d ${cfg.modelDir} 2775 root ${cfg.group} -"
      ];

      environment.etc."aider/aider.conf.yml".source = aiderConfYml;
      environment.etc."aider/aider.model.settings.yml".source = aiderModelSettingsYml;
      environment.variables.AIDER_CONFIG_FILE = "/etc/aider/aider.conf.yml";
    }

    (lib.mkIf cfg.foreground.enable {
      systemd.services.llama-foreground = mkLlamaService {
        tier = "foreground";
        tierCfg = cfg.foreground;
      };
    })

    (lib.mkIf cfg.background.enable {
      systemd.services.llama-background = mkLlamaService {
        tier = "background";
        tierCfg = cfg.background;
      };
    })

    (lib.mkIf cfg.openTailscale {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts =
        lib.optional cfg.foreground.enable cfg.foreground.port
        ++ lib.optional cfg.background.enable cfg.background.port;
    })
  ]);
}
