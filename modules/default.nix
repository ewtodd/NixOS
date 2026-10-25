{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
{
  imports = [
    ./desktopEnvironment
    ./hardware
    ./packages
    ./secrets
    ./security
    ./services
  ];

  options = {
    systemOptions = {
      graphics.amd.enable = mkEnableOption "AMD graphics";
      graphics.intel.enable = mkEnableOption "Intel graphics";
      graphics.nvidia.enable = mkEnableOption "NVIDIA proprietary graphics (latest driver)";
      graphics.asahi.enable = mkEnableOption "Asahi graphics (Apple Silicon GPU via Mesa)";

      hardware.chromebook-audio.enable = mkEnableOption "Chromebook audio fixes";
      hardware.suzyqable.enable = mkEnableOption "Suzyqable chromebook debugging support";
      hardware.fingerprint.enable = mkEnableOption "Fprintd support";
      hardware.openRGB.enable = mkEnableOption "openRGB support";
      hardware.xbox.enable = mkEnableOption "xbox controller support";
      hardware.frameworkLaptop.enable = mkEnableOption "Framework laptop specific features (fw-fanctrl)";
      hardware.twoinone.enable = mkEnableOption "2-in-1 specific features";

      deviceType.laptop.enable = mkEnableOption "Laptop-specific features";
      deviceType.desktop.enable = mkEnableOption "Desktop-specific features";
      deviceType.server.enable = mkEnableOption "Headless server (skips desktop environment, GUI packages, and audio/bluetooth/printing stacks)";

      aiFrontAddress = mkOption {
        type = types.str;
        default = "10.0.0.2";
        description = ''
          LAN address of the host serving the house's AI front: maitred (/v1 and /mcp on :4002),
          Open WebUI (:8081) and SearXNG (:8888). nu's reverse proxy and the clients
          point here, so moving those services to another machine changes only this. mu since oracle was
          decommissioned.
        '';
      };

      apps.zoom.enable = mkEnableOption "Zoom";
      apps.remarkable.enable = mkEnableOption "Remarkable from wrapWine flake";
      apps.quickemu.enable = mkEnableOption "Quickemu";
      apps.docker.enable = mkEnableOption "Docker";

      services.ssh.enable = mkEnableOption "SSH with non-standard port";
      services.suspend-then-hibernate.enable = mkEnableOption "Suspend then hibernate";
      services.binaryCache.serve = mkEnableOption "Serve the nix store as a binary cache via nix-serve, exposed through Caddy on nu";
      services.binaryCache.consume = mkEnableOption "Use the e-desktop binary cache as a substituter";
      services.router.enable = mkEnableOption "Act as a NAT router (WAN DHCP, LAN static, dnsmasq DHCP+DNS)";
      services.adguard.enable = mkEnableOption "AdGuard Home DNS ad-blocker (sits behind dnsmasq)";
      services.reverseProxy.enable = mkEnableOption "Caddy reverse proxy with auto-TLS";
      services.dyndns.enable = mkEnableOption "Namecheap dynamic DNS updater for ethanwtodd.com subdomains";
      services.bastion.enable = mkEnableOption "SSH bastion: hardened sshd + fail2ban + WoL helpers for inner hosts";
      services.bastion.wakeCalendar = mkOption {
        type = types.str;
        default = "";
        example = "Sun,Wed *-*-* 05:10:00";
        description = ''
          OnCalendar expression for waking and unlocking e-desktop from here.
          Empty disables it.

          This is the other half of e-desktop's scheduled poweroff: the
          machine shuts down on its own schedule, and this brings it back a
          few minutes later over WoL, pushing the LUKS passphrase into its
          initrd exactly as the relay does. Together they are an unattended
          reboot for a host that cannot reboot unattended, since nothing on
          e-desktop itself can unlock its own root volume.
        '';
      };
      services.wakeable.enable = mkEnableOption "Wake-on-LAN + initrd-SSH for remote unlock";
      services.nextcloud.enable = mkEnableOption "Nextcloud personal cloud (cloud.ethanwtodd.com)";
      services.prometheus.enable = mkEnableOption "Prometheus metrics server (scrapes node_exporters)";
      services.prometheus.wireviewTarget = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "10.0.0.4:9877";
        description = "host:port of the wireview-monitor exporter to scrape (adds a `wireview` job).";
      };
      services.nodeExporter.enable = mkEnableOption "Prometheus node_exporter (system metrics on :9100)";
      services.grafana.enable = mkEnableOption "Grafana dashboards (status.ethanwtodd.com)";
      services.wireview-monitor = {
        enable = mkEnableOption "WireView Pro II Prometheus exporter (reads the device over /dev/ttyACM*, serves /metrics)";
        port = mkOption {
          type = types.ints.positive;
          default = 9877;
          description = "TCP port for the Prometheus /metrics endpoint.";
        };
        listenAddress = mkOption {
          type = types.str;
          default = "0.0.0.0";
          description = "Address the exporter binds (0.0.0.0 so the fleet Prometheus on nu can scrape it).";
        };
      };
      services.wireview-safety = {
        enable = mkEnableOption "WireView safety watchdog: power off the machine when the WireView reports a sustained dangerous condition (fault or over-temperature)";
        metricsUrl = mkOption {
          type = types.str;
          default = "http://127.0.0.1:9877/metrics";
          description = "URL of the wireview-monitor exporter to poll.";
        };
        pollIntervalSeconds = mkOption {
          type = types.ints.positive;
          default = 5;
          description = "Seconds between checks of the exporter metrics.";
        };
        consecutiveHits = mkOption {
          type = types.ints.positive;
          default = 3;
          description = "How many consecutive checks must show a dangerous condition before acting (debounce).";
        };
        tempThresholdC = mkOption {
          type = types.float;
          default = 85.0;
          description = "Power off when any WireView temperature stays at or above this (belt and braces on top of the firmware OTP fault).";
        };
        triggerOnFaults = mkOption {
          type = types.bool;
          default = true;
          description = "Act on any WireView fault bit (OTP, OCP, wire OCP, OPP, current imbalance).";
        };
        action = mkOption {
          type = types.enum [
            "poweroff"
            "reboot"
          ];
          default = "poweroff";
          description = "What to do when a dangerous condition is sustained.";
        };
        dryRun = mkOption {
          type = types.bool;
          default = false;
          description = "Log the trigger without acting (safe for testing the watchdog).";
        };
      };
      services.minecraft.enable = mkEnableOption "Public PaperMC Minecraft server (mc.ethanwtodd.com:25565)";

      services.openWebUI.enable = mkEnableOption "Open WebUI web interface (ai.ethanwtodd.com, behind Anubis on nu)";

      services.llamaCpp.enable = mkEnableOption "llama.cpp model servers (one llama-server per model)";

      services.llamaCpp.lanExpose = mkEnableOption ''
        expose the llama.cpp servers on the LAN (bind 0.0.0.0 + open the
        firewall). Off (the default) binds 127.0.0.1 only — correct for hosts
        where the sole consumer is local (e.g. maitred on the same box). Enable
        it on hosts another machine must reach directly.'';
      services.llamaCpp.backend = mkOption {
        type = types.enum [
          "vulkan"
          "cuda"
          "rocm"
          "cpu"
        ];
        default = "vulkan";
        description = "llama.cpp backend: Vulkan (AMD RADV or Intel ANV), CUDA (NVIDIA), ROCm, or CPU only.";
      };
      services.llamaCpp.vulkanDriver = mkOption {
        type = types.nullOr (
          types.enum [
            "intel"
            "radeon"
            "asahi"
          ]
        );
        default = null;
        description = ''
          Mesa Vulkan driver (ICD) the Vulkan backend binds. Null picks it from
          systemOptions.graphics.*; set it on hosts that enable none of those
          (a headless box whose GPU only runs llama.cpp).
        '';
      };
      services.llamaCpp.cacheDir = mkOption {
        type = types.nullOr types.str;
        default = "/var/cache/llama-cache";
        example = "/scratch/llama-cache";
        description = ''
          Directory for -hf model downloads (LLAMA_CACHE). Default is a
          systemd-managed CacheDirectory under /var/cache; set this to keep large
          models on a big mount (the module provisions it with a shared group so
          the sandboxed service can write to it).
        '';
      };
      services.llamaCpp.verboseLogging = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Run every llama-server with --verbose (per-token timing, full debug
          output — extremely chatty, so off by default). Output lands in each
          unit's systemd journal (journalctl -u llama-server-NAME).
        '';
      };
      services.llamaCpp.models = mkOption {
        default = { };
        description = "Models served as standalone llama-server systemd units; the module builds each command.";
        type = types.attrsOf (
          types.submodule {
            options = {
              path = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Local GGUF path (first shard). Mutually exclusive with `hf`.";
              };
              hf = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Hugging Face repo[:quant] for llama.cpp -hf auto-download
                  (e.g. "Qwen/Qwen2.5-Coder-14B-Instruct-GGUF:Q5_K_M").
                  Mutually exclusive with `path`.
                '';
              };
              port = mkOption {
                type = types.port;
                default = 8080;
                description = ''
                  OpenAI-compatible port for this model's llama-server
                  (--port). Every model runs at once, so each needs a port
                  distinct from the others.
                '';
              };
              ctxSize = mkOption {
                type = types.ints.positive;
                default = 32768;
                description = "Context size (--ctx-size), sized for agentic/MCP use.";
              };
              mmproj = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = ''
                  Path to a multimodal projector (mmproj) GGUF to enable vision
                  via `--mmproj`. For vision-language models whose projector
                  isn't auto-pulled by `-hf` (e.g. Qwen3-VL). Chat models only.
                '';
              };
              mmprojDevice = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Device for multimodal projector.
                '';
              };
              device = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Value for llama.cpp --device (e.g. "ROCm0", or a comma list
                  "ROCm0,ROCm1,ROCm2" to span several devices). Null lets
                  llama.cpp pick the device.
                '';
              };
              gpuLayers = mkOption {
                type = types.str;
                default = "999";
                example = "\"auto\"";
                description = ''
                  Value for --n-gpu-layers. Use "999" to offload all layers (the
                  default), or "auto" to let llama.cpp decide (useful for large MoE
                  models like DeepSeek V4 Flash that may not offload cleanly).
                '';
              };
              splitMode = mkOption {
                type = types.nullOr (
                  types.enum [
                    "layer"
                    "row"
                    "tensor"
                  ]
                );
                default = null;
                description = ''
                  Value for --split-mode (how tensors are split across
                  devices). Only relevant for multi-device models.
                '';
              };
              tensorSplit = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Value for --tensor-split (proportional VRAM split across
                  devices, e.g. "1,1,4"). Only relevant for multi-device
                  models.
                '';
              };
              loadMode = mkOption {
                type = types.enum [
                  "auto"
                  "none"
                  "mmap"
                  "mlock"
                  "mmap+mlock"
                  "dio"
                ];
                default = "auto";
                description = ''
                  model loading mode (default: auto)
                  - auto: mmap, unless a device does not support it
                  - none: no special loading mode
                  - mmap: memory-map model (if mmap disabled, slower load but may reduce pageouts if not using mlock)
                  - mlock: force system to keep model in RAM rather than swapping or compressing
                  - mmap+mlock: mmap + force system to keep model in RAM rather than swapping or compressing
                  - dio: use DirectIO if available                '';
              };
              flashAttn = mkOption {
                type = types.str;
                default = "auto";
                example = "on";
                description = "Value for --flash-attn (auto, on, off).";
              };
              batchSize = mkOption {
                type = types.ints.positive;
                default = 2048;
                description = "Value for --batch-size.";
              };
              ubatchSize = mkOption {
                type = types.ints.positive;
                default = 2048;
                description = "Value for --ubatch-size.";
              };
              cacheReuse = mkOption {
                type = types.nullOr types.ints.positive;
                default = null;
                description = ''
                  Value for --cache-reuse (KV cache tokens to reuse between
                  requests). Set to null to omit the flag entirely.
                '';
              };
              cacheRam = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = ''
                  Value for --cache-ram: maximum prompt-cache size in MiB,
                  holding context checkpoints across requests (llama.cpp
                  default: 8192; -1 = unlimited, 0 = disable). Raise it on
                  memory-rich hosts (e.g. the Strix Halo) when serving
                  long-context sessions: each cached 50K-token prompt costs
                  several GiB, so the 8 GiB default holds only one.
                '';
              };
              ctxCheckpoints = mkOption {
                type = types.nullOr types.ints.positive;
                default = null;
                description = ''
                  Value for --ctx-checkpoints: max number of context
                  checkpoints per slot (llama.cpp default: 32). Each
                  checkpoint snapshots the KV state so a later request
                  sharing the prefix restores it instead of re-prefilling
                  the whole context.
                '';
              };
              checkpointMinStep = mkOption {
                type = types.nullOr types.ints.unsigned;
                default = null;
                description = ''
                  Value for --checkpoint-min-step: minimum spacing between
                  context checkpoints in tokens (llama.cpp default: 8192,
                  0 = no minimum).
                '';
              };
              parallel = mkOption {
                type = types.nullOr types.ints.positive;
                default = null;
                description = ''
                  Value for --parallel (number of parallel request slots).
                  Set to null to omit the flag (llama-server's default).
                  Use 1 for models that fail under concurrent requests.
                '';
              };
              nCpuMoe = mkOption {
                type = types.nullOr types.ints.positive;
                default = null;
                description = ''
                  Value for --n-cpu-moe (number of MoE experts to run on CPU).
                  Set to null to omit the flag.
                '';
              };
              chatTemplateFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = ''
                  Path to a Jinja chat template file, emitted as
                  --chat-template-file PATH. Set to null to omit.
                '';
              };
              noWarmup = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to emit --no-warmup (skip KV cache warmup on model load).
                  Useful for very large models where warmup is slow or fails.
                '';
              };
              noRepack = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to emit --no-repack (disable KV cache repacking).
                  Some models produce garbled output with repacking enabled.
                '';
              };
              reasoningPreserve = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to emit --reasoning-preserve (keep reasoning traces
                  across turns, not just the last assistant message). Requires
                  a chat template with the supports_preserve_reasoning
                  capability; no-op otherwise.
                '';
              };
              hfFile = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Specific filename within a Hugging Face repo, emitted as
                  --hf-file FILE after -hf. Used when the default auto-pick is
                  wrong. Ignored if `path` is set instead of `hf`.
                '';
              };
              # separate options to allow for assymmetric quant
              kQuant = mkOption {
                type = types.enum [
                  "f32"
                  "f16"
                  "bf16"
                  "q8_0"
                  "q4_0"
                  "q4_1"
                  "iq4_nl"
                  "q5_0"
                  "q5_1"
                ];
                default = "q8_0";
                description = "i.e. --cache-type-k q8_0";
              };
              vQuant = mkOption {
                type = types.enum [
                  "f32"
                  "f16"
                  "bf16"
                  "q8_0"
                  "q4_0"
                  "q4_1"
                  "iq4_nl"
                  "q5_0"
                  "q5_1"
                ];
                default = "q8_0";
                description = "i.e. --cache-type-v q8_0";
              };
              specType = mkOption {
                type = types.enum [
                  "none"
                  "draft-simple"
                  "draft-eagle3"
                  "draft-dflash"
                  "draft-dspark"
                  "draft-mtp"
                  "ngram-cache"
                  "ngram-simple"
                  "ngram-map-k"
                  "ngram-map-k4v"
                  "ngram-mod"
                ];
                default = "ngram-mod";
              };
              specDraftNMax = mkOption {
                type = types.ints.positive;
                default = 3;
              };
              specDraftModel = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = ''
                  Local GGUF path for the speculative draft model, emitted as
                  --spec-draft-model PATH. Mutually exclusive with
                  `specDraftHf`.
                '';
              };
              specDraftHf = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Hugging Face repo[:quant] for the speculative draft model,
                  emitted as --spec-draft-hf (auto-downloaded to
                  LLAMA_CACHE). Mutually exclusive with `specDraftModel`.
                '';
              };
              specDraftDevice = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Value for --spec-draft-device (device that hosts the
                  speculative draft model, e.g. "ROCm2"). Null lets llama.cpp
                  pick.
                '';
              };
              extraFlags = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra llama-server flags.";
              };
            };
          }
        );
      };
      services.llamaCpp.embeddingModel = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              path = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Local GGUF path. Mutually exclusive with `hf`.";
              };
              hf = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Hugging Face repo[:file] for llama.cpp -hf auto-download.";
              };
              hfFile = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Explicit file within the -hf repo (--hf-file).";
              };
              backend = mkOption {
                type = types.nullOr (
                  types.enum [
                    "vulkan"
                    "cuda"
                    "rocm"
                    "cpu"
                  ]
                );
                default = null;
                description = "llama.cpp backend for the embedding server; null uses services.llamaCpp.backend.";
              };
              gpuLayers = mkOption {
                type = types.ints.unsigned;
                default = 99;
                description = "--n-gpu-layers for the embedding model (0 = CPU-only).";
              };
              pooling = mkOption {
                type = types.enum [
                  "none"
                  "mean"
                  "cls"
                  "last"
                ];
                default = "mean";
                description = "llama.cpp --pooling (bge models: mean or cls).";
              };
              ctxSize = mkOption {
                type = types.ints.positive;
                default = 8192;
                description = "--ctx-size for embedding batches.";
              };
              port = mkOption {
                type = types.port;
                default = 8082;
                description = "Dedicated OpenAI-compatible /v1/embeddings endpoint port.";
              };
            };
          }
        );
        default = null;
        description = ''
          Run a dedicated llama.cpp embedding server (llama-server
          --embedding) as its own always-on unit, separate from the chat
          models. Serves Open WebUI RAG (e.g. bge-m3).
        '';
      };
      services.gufoStrix = {
        enable = mkEnableOption "gufo Strix Halo inference server on the gfx1151 iGPU";
        lanExpose = mkEnableOption "expose the gufo-strix server on the LAN (bind 0.0.0.0 + open firewall)";
        model = mkOption {
          type = types.str;
          example = "/scratch/models/gufo/qwen3.8-flash-next/Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf";
          description = "Absolute path to the main GGUF (first shard for split models).";
        };
        mtpModel = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/scratch/models/gufo/qwen3.8-flash-next/mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf";
          description = "MTP draft sidecar (--speculative mtp). Null disables speculative decoding.";
        };
        mmproj = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/scratch/models/gufo/qwen3.8-flash-next/mmproj-BF16.gguf";
          description = "Vision projector GGUF (--mmproj). Null serves text only.";
        };
        releaseGpuPagePool = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Drop caches (as root) just before gufo starts, so pages the amdgpu TTM pool kept from an earlier GPU
            process count as available again: gufo sizes its RAM snapshot cache from MemAvailable, and a pool-held
            box makes it far too small (fewer parked sessions, ~30% less throughput above `sessions` requests).
          '';
        };
        alias = mkOption {
          type = types.str;
          default = "qwen3.8-flash-next";
          description = "Model name reported on /v1/models (--served-model-name).";
        };
        port = mkOption {
          type = types.port;
          default = 8050;
        };
        sessions = mkOption {
          type = types.ints.positive;
          default = 3;
          description = ''
            Preallocated GPU request sessions (--sessions). Each session reserves its
            full context up front; a 128 GiB Strix Halo fits three MTP sessions at
            262144 or four AR sessions.
          '';
        };
        context = mkOption {
          type = types.ints.positive;
          default = 262144;
          description = ''
            Context tokens per session (--context). Flash-Next's native
            context is 262144; above it the module passes gufo's
            --enable-yarn flag (gufo PR #350, now upstream), which applies
            static YaRN with factor = context / 262144 to every request,
            including short ones. The engine refuses to start above the
            native context without it, and rejects it at or below. State
            grows about 27.5 KiB per context token per MTP session, so plan
            against the 128 GiB unified memory together
            with {option}`sessions`.
          '';
        };
        yarn = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = ''
            Expect static YaRN rope scaling (gufo's --enable-yarn, PR #350,
            now upstream) to be active. Null accepts whatever follows from
            {option}`context` (on exactly above the native 262144);
            true or false additionally fails evaluation when
            {option}`context` disagrees, catching an unintended silent
            rope-scale change in review.
          '';
        };
        diskCacheDir = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/scratch/gufo-cache";
          description = ''
            Restart-safe continuation cache directory (--cache-disk).
            Snapshots are bound to their YaRN factor, so a session saved
            at one context is never restored at another. Null disables
            the disk cache.
          '';
        };
        diskCacheBytes = mkOption {
          type = types.nullOr types.ints.unsigned;
          default = null;
          description = ''
            Retained disk-cache byte budget (--cache-disk-bytes). Null
            keeps the engine's 8 GiB default, which is smaller than one
            full snapshot at extended contexts (~27.5 KiB per context
            token per session: ~14 GiB at 524288).
          '';
        };
        cacheRamBytes = mkOption {
          type = types.nullOr types.ints.unsigned;
          default = null;
          example = 1;
          description = ''
            Retained RAM snapshot byte budget (--cache-ram-bytes). Null
            keeps the engine's automatic budget: half the free RAM at
            startup, at most 32 GiB, which it reserves on top of the
            session preallocation. 0 also means automatic, not off; a tiny
            explicit value is the off switch -- snapshots above the budget
            are written straight to the disk cache instead of being held
            in RAM, so with diskCacheDir set it buys unified-RAM headroom
            at the cost of a disk re-read per restore.
          '';
        };
        logProgress = mkEnableOption "per-request progress lines including MTP draft_accepted/draft_proposed/acceptance_percentage (--log-progress; needs log level info or above)";
        logLevel = mkOption {
          type = types.nullOr (
            types.enum [
              "error"
              "warn"
              "info"
              "debug"
            ]
          );
          default = null;
          description = "Log verbosity (--log-level). Null keeps the engine default (info).";
        };
        think = mkOption {
          type = types.nullOr (
            types.enum [
              "on"
              "off"
              "auto"
            ]
          );
          default = null;
          description = "Reasoning mode (--think). Null keeps the model default.";
        };
        draftTokens = mkOption {
          type = types.ints.positive;
          default = 7;
          description = "Maximum speculative MTP draft tokens evaluated per step (--draft-tokens).";
        };
        user = mkOption {
          type = types.str;
          default = "son-of-anton";
        };
        devices = mkOption {
          type = types.str;
          default = "2";
          description = ''
            HIP_VISIBLE_DEVICES. On son-of-anton the two R9700s are 0,1 (Radiance's or
            unholy's) and the Strix Halo iGPU (gfx1151) is 2.
          '';
        };
        extraEnv = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Extra environment for gufo serve; merged last.";
        };
        extraFlags = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
      };
      services.radiance = {
        enable = mkEnableOption "Radiance inference server (C++/HIP, built from source by radiance-nix) on the R9700s";
        lanExpose = mkEnableOption "expose Radiance on the LAN (bind 0.0.0.0 + open firewall)";
        model = mkOption {
          type = types.str;
          example = "/scratch/models/rad/qwen3.8-27b-fp8/qwen3.8-27b-fp8.rad";
          description = "A .rad container (rad-convert) or a checkpoint at its own precision.";
        };
        servedModelName = mkOption {
          type = types.str;
          default = "qwen3.8-27b";
        };
        port = mkOption {
          type = types.port;
          default = 8100;
        };
        tp = mkOption {
          type = types.ints.positive;
          default = 2;
          description = "Tensor-parallel ranks (--tp), one per visible card.";
        };
        maxModelLen = mkOption {
          type = types.ints.positive;
          default = 262144;
          description = "Context per request (--max-model-len). Above the container's 262144, pair it with ropeScaling.";
        };
        maxNumSeqs = mkOption {
          type = types.ints.positive;
          default = 8;
          description = "Sequences per step (--max-num-seqs); each holds its own delta-net state.";
        };
        kvCacheDtype = mkOption {
          type = types.enum [
            "bf16"
            "fp8"
          ];
          default = "bf16";
          description = "KV-cache element type (--kv-cache-dtype).";
        };
        numSpeculativeTokens = mkOption {
          type = types.nullOr types.ints.unsigned;
          default = null;
          description = "Draft tokens per step for the container's drafter (--num-speculative-tokens). Null keeps the drafter's own operating point.";
        };
        maxNumBatchedTokens = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = "Tokens per engine step (--max-num-batched-tokens). Null keeps the engine default.";
        };
        ropeScaling = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "yarn:1.34375";
          description = "Static YaRN over the container's rotary embedding (--rope-scaling yarn:FACTOR[:ORIG]).";
        };
        prefixCacheMib = mkOption {
          type = types.nullOr types.ints.unsigned;
          default = null;
          description = ''
            Host-RAM prefix tier (--prefix-cache-mib): finished
            conversations' KV copied out of VRAM to pinned host memory, so
            their VRAM goes to the experts and a return restores instead of
            re-prefilling. 0 is off and is radiance 1.4.0's default; null
            leaves the engine default alone. There is no disk tier in the
            locked radiance (see radiance-nix), so RAM is the only place
            finished KV can live.
          '';
        };
        checkpointSlots = mkOption {
          type = types.nullOr types.ints.unsigned;
          default = null;
          description = ''
            Linear-state snapshots held in pinned host memory
            (--checkpoint-slots). Null keeps `auto`: what the checkpoint
            policy keeps for a max-model-len session plus one per
            max-num-seqs, capped at an eighth of host memory. At 352256
            context that can pin many GiB on top of everything else; 0
            keeps none (a prefix hit then replays the hybrid's linear
            layers from zero), N fixes the total.
          '';
        };
        devices = mkOption {
          type = types.str;
          default = "0,1";
          description = "HIP_VISIBLE_DEVICES: the two R9700s (the iGPU is gufo's).";
        };
        user = mkOption {
          type = types.str;
          default = "son-of-anton";
        };
        extraEnv = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Extra environment for radiance; merged last.";
        };
        extraFlags = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
      };
      services.llmMode = {
        enable = mkEnableOption ''
          the `llm-mode <mode>|status` switch between the model sets sharing son-of-anton's GPUs: each
          services.unholy instance (all three GPUs) is a mode of its own name, and `qwen` the Qwen pair
          (services.radiance on the R9700s + services.gufoStrix on the iGPU), with no redeploy'';
        default = mkOption {
          type = types.str;
          default = "ds4";
          description = "Mode started at boot until `llm-mode` has recorded a choice: an unholy instance or `qwen`.";
        };
        managers = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "son-of-anton" ];
          description = "Users allowed to switch modes and start/stop the model services without sudo (polkit).";
        };
      };
      services.unholy = {
        enable = mkEnableOption ''
          unholy, the DeepSeek-V4-Flash and GLM-5.3-Flash engine across both R9700s and the Strix Halo
          iGPU, one unholy-<name>.service per instance. Each needs all three GPUs, so the instances conflict
          with each other and cannot run alongside services.radiance or services.gufoStrix unless
          services.llmMode switches between them'';
        lanExpose = mkEnableOption "expose the unholy instances on the LAN (bind 0.0.0.0 + open their ports)";
        devices = mkOption {
          type = types.str;
          default = "0,1,2";
          description = "HIP_VISIBLE_DEVICES: the two R9700s, then the iGPU.";
        };
        user = mkOption {
          type = types.str;
          default = "son-of-anton";
        };
        managers = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "son-of-anton" ];
          description = ''
            Users allowed to start, stop and restart the unholy-*.service units without sudo (a polkit
            rule), e.g. to free the GPUs for development runs.
          '';
        };
        instances = mkOption {
          default = { };
          description = "Model servers by name, each unholy-<name>.service; unholy serve picks the engine from the checkpoint.";
          type = types.attrsOf (
            types.submodule {
              options = {
                model = mkOption {
                  type = types.str;
                  example = "/scratch/dsv4-ve";
                  description = ''
                    Checkpoint directory: native DeepSeek-V4-Flash (config, tokenizer, dense and MXFP4 expert
                    weights) or a GLM-5.3-Flash EXL3 quant.
                  '';
                };
                exl3 = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "DeepSeek-V4-Flash: an EXL3 quant whose routed experts replace the native MXFP4 ones. Null serves the native experts.";
                };
                profile = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = ''
                    Expert routing profile used to place hot experts on the cards (--profile). Null uses the
                    profile the package ships for the model family.
                  '';
                };
                servedModelName = mkOption {
                  type = types.str;
                  example = "dsv4-flash";
                };
                port = mkOption {
                  type = types.port;
                };
                kvTokens = mkOption {
                  type = types.ints.positive;
                  default = 1048576;
                  description = ''
                    KV cache pool in tokens, shared by all requests (--kv-tokens), as vLLM's cache: a request
                    takes 256-token pages as it grows. Every GB of pool displaces ~80 hot experts from the
                    cards (see `unholy plan`).
                  '';
                };
                maxModelLen = mkOption {
                  type = types.ints.positive;
                  default = 524288;
                  description = "Maximum tokens per request, prompt + completion (--max-model-len).";
                };
                maxNumSeqs = mkOption {
                  type = types.ints.positive;
                  default = 8;
                  description = "Requests running at once (--max-num-seqs).";
                };
                maxBatchTokens = mkOption {
                  type = types.ints.positive;
                  default = 4096;
                  description = "Tokens per engine step (--max-batch-tokens): decode tokens first, prefill chunks fill the rest.";
                };
                specDrafts = mkOption {
                  type = types.ints.between 0 5;
                  default = 0;
                  description = ''
                    Speculative decoding (--spec-drafts; 0 turns it off): DeepSeek-V4-Flash drafts this many
                    tokens per step with its DSpark drafter (~10 GB of experts in the iGPU's share of RAM),
                    GLM-5.3-Flash one with its MTP layer for any value above 0. Outputs are exactly what the
                    model would produce without it.
                  '';
                };
                prefixSnapshots = mkOption {
                  type = types.ints.unsigned;
                  default = 128;
                  description = ''
                    Slot-state snapshots kept for prefix caching (--prefix-snapshots), in pinned host memory:
                    ~7 MB each for DeepSeek-V4-Flash, ~148 MB for GLM-5.3-Flash (as many as fit beside the
                    iGPU's experts). A request that repeats an earlier prefix (the next chat turn, a shared
                    system prompt) resumes from the deepest saved page boundary it matches. 0 turns prefix
                    caching off.
                  '';
                };
                extraEnv = mkOption {
                  type = types.attrsOf types.str;
                  default = { };
                  description = "Extra environment for unholy serve; merged last.";
                };
                extraFlags = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
              };
            }
          );
        };
      };
      services.eklow = {
        enable = mkEnableOption "eklow (github.com/ewtodd/eklow): Gemma 4 and EmbeddingGemma 2 on an Intel Arc A770M";
        lanExpose = mkEnableOption "eklow on the LAN (0.0.0.0, ports open) for maitred";
      };
      services.maitred = {
        enable = mkEnableOption "maitred (github.com/ewtodd/maitred): the /v1 front for the LLM servers and the /mcp gateway";
        port = mkOption {
          type = types.port;
          default = 4002;
          description = "Listen port (nu's Caddy and the clients use 4002).";
        };
        openFirewall = mkOption {
          type = types.bool;
          default = true;
        };
        environmentFiles = mkOption {
          type = types.listOf types.path;
          default = [ ];
          description = "Files with the key variables (MAITRED_KEY_*) and DEEPSEEK_API_KEY.";
        };
      };
      services.httpTarpit.enable = mkEnableOption "HTTP tarpit (endless slow-drip responses for WAN scanners)";
      # One system service per account (the temple design): each instance runs AS its account with
      # SON_OF_ANTON_HOME=~/.son-of-anton, so Signal and CLI sessions share one state.db/config.toml/writer.
      # All instances share one Signal number, separated by group id: signal-cli broadcasts every event over
      # SSE and each instance drops foreign groups before any session or agent work.
      services.son-of-anton = {
        enable = mkEnableOption "son-of-anton gateway services (successor to the temple daemon)";
        instances = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                user = mkOption {
                  type = types.str;
                  description = "Account this instance runs as.";
                };
                createUser = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Create the account. False for pre-existing login accounts.";
                };
                managedAccount = mkOption {
                  type = types.bool;
                  default = true;
                  description = ''
                    The account is a pre-existing HUMAN login account, so the
                    module touches only SON_OF_ANTON_HOME and never chmods the
                    parent home (which would break sshd StrictModes) or the
                    working directory.
                  '';
                };
                stateDir = mkOption {
                  type = types.str;
                  default = "";
                  description = ''
                    HOME for the unit, for a created (non-login) account.
                    Empty means the account is a login account and its own home
                    is used. Set it wherever son-of-antonHome lives, or the unit
                    gets a HOME unrelated to its SON_OF_ANTON_HOME.
                  '';
                };
                son-of-antonHome = mkOption {
                  type = types.str;
                  description = "SON_OF_ANTON_HOME: config, skills, memory, sessions.";
                };
                workingDirectory = mkOption {
                  type = types.str;
                  description = "terminal.cwd — where this instance's agent runs commands.";
                };
                environmentFiles = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = ''
                    Secret files for THIS instance, appended to the shared ones
                    and therefore overriding them (later .env lines win).

                    This is where the routing lives. SIGNAL_GROUP_ALLOWED_USERS
                    is the group id this instance answers and the only thing
                    that routes a message here rather than to a sibling;
                    SIGNAL_ALLOWED_USERS is the default-deny sender allowlist,
                    enforced on group messages too. Both identify real people
                    and real chats, and this repo is public, so neither may be
                    written in Nix.
                  '';
                };
                model = mkOption {
                  type = types.str;
                  default = "";
                  description = ''
                    Model this instance answers with over Signal, written as
                    `gateway.model`. Empty inherits settings.model.default,
                    which is what this account's CLI opens with.
                  '';
                };
                protectedPaths = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = "Extra credential paths made inaccessible to the unit.";
                };
                git = mkOption {
                  type = types.attrs;
                  default = { };
                  description = ''
                    Git credentials for THIS instance. `git.github` is a
                    runtime path to a *private* SSH key (OpenSSH format) whose
                    public half is on GitHub; the son-of-anton module installs it
                    and a routing ssh config into the instance HOME so the agent
                    can clone and push over ssh.
                  '';
                };
                settings = mkOption {
                  type = types.attrs;
                  default = { };
                  description = ''
                    config.toml overrides for THIS instance, deep-merged over
                    the shared `settings`. Use it for anything an instance
                    should differ on, e.g. `gateway.single_user = true` for an
                    instance that is one person's own.
                  '';
                };
                extraPackages = mkOption {
                  type = types.listOf types.package;
                  default = [ ];
                  description = ''
                    Tools on THIS instance's PATH, on top of the shared ones.
                    The agent can run them from its terminal tool.

                    Per-instance because capability is per-account: the house
                    agent acts for whoever speaks in a shared group, so it gets
                    only what that group needs.
                  '';
                };
              };
            }
          );
          default = { };
          description = "Gateway instances, one system service per account.";
        };
        environmentFiles = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Secret files whose contents land in each instance's .env (agenix paths).";
        };
        environment = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Non-secret environment variables written to each instance's .env.";
        };
        settings = mkOption {
          type = types.attrs;
          default = { };
          description = "config.toml settings shared by every instance (and by each account's CLI).";
        };
        extraPackages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Extra packages available to every instance.";
        };
      };
      services.signal-cli.enable = mkEnableOption "signal-cli JSON-RPC daemon in HTTP mode (Signal bot backend for son-of-anton)";
      services.signal-cli.environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/agenix/signal-cli-env";
        description = ''
          EnvironmentFile containing SIGNAL_PHONE=+15551234567 (the bot's
          registered number, E.164 with + prefix).
        '';
      };
      services.signal-cli.socketAddr = mkOption {
        type = types.str;
        default = "127.0.0.1:7583";
        description = "Listen address for the HTTP JSON-RPC daemon.";
      };
      services.signal-cli.dataDir = mkOption {
        type = types.path;
        default = "/var/lib/signal-cli";
        description = "State directory: keys, registration data.";
      };
      services.signal-cli.openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Open the JSON-RPC HTTP port in the firewall (needed when the gateway runs on a different host).";
      };

      services.deploy.enable = mkEnableOption ''
        colmena deploy target: a key-only `deploy` user with scoped NOPASSWD sudo
        (just the activation commands) and nix trusted-user, so the build host
        (e-desktop) can push and switch closures remotely'';
      services.scheduledReboot.enable = mkEnableOption "Reboot the machine on a systemd OnCalendar schedule";
      services.scheduledReboot.calendar = mkOption {
        type = types.str;
        default = "*-*-* 04:00:00";
        example = "*-*-* 04:30:00";
        description = "systemd OnCalendar expression for the scheduled reboot (time zone follows time.timeZone).";
      };
      services.scheduledReboot.action = mkOption {
        type = types.enum [
          "reboot"
          "poweroff"
        ];
        default = "reboot";
        description = ''
          What the timer does. `poweroff` is for a machine that cannot come
          back on its own: e-desktop's root and home are both LUKS volumes
          unlocked from the bastion's wake-and-relay script, which only runs
          when someone connects through it. Rebooting would leave the machine
          sitting in initrd until then; powering off means the next connection
          wakes it over WoL and unlocks it, which is the path that already
          exists.
        '';
      };
      services.rgbLoad.enable = mkEnableOption "load-reactive RGB lighting (drives color from max of CPU/GPU utilization)";
      services.rgbLoad.backend = mkOption {
        type = types.enum [
          "openrgb"
          "framework"
        ];
        default = "openrgb";
        description = "Lighting backend: the OpenRGB SDK server, or `framework_tool --rgbkbd`.";
      };

      services.rgbStatic.enable = mkEnableOption ''
        fixed OpenRGB colours, applied at boot and after resume. The
        alternative to services.rgbLoad for a machine that just wants its
        lighting to sit on one colour and stay there'';
      services.rgbStatic.defaultColor = mkOption {
        type = types.str;
        default = "FF00FF";
        example = "F600C9";
        description = "Hex RGB colour applied to every device without a `deviceColors` entry.";
      };
      services.rgbStatic.deviceColors = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          "MSI MPG" = "FF0B71";
        };
        description = ''
          Per-device overrides, keyed by a case-insensitive substring of the
          OpenRGB device name (`openrgb --list-devices`). Panels and diffusers
          differ enough that one hex does not read as the same colour across
          RAM, a GPU shroud and an ARGB strip, so these are the values matched
          by eye. Applied per device; zones within a device share a colour.
        '';
      };
      services.rgbStatic.expectedDevices = mkOption {
        type = types.ints.unsigned;
        default = 0;
        example = 4;
        description = ''
          How many controllers `openrgb --list-devices` reports on this host.
          The SDK server starts listening part-way through enumeration, so a
          client that connects at boot sees a partial list and silently leaves
          the late arrivals dark; this is the count to wait for. 0 falls back to
          waiting for the list to stop growing, which is only a timing guess.
          The unit fails (having coloured whatever it did find) if the count is
          never reached, so a hardware change shows up instead of going quiet.
        '';
      };

      security.harden.enable = mkEnableOption "Try to reasonably harden NixOS";
      owner.e.enable = mkEnableOption "Whether this is an e-device";
      owner.v.enable = mkEnableOption "Whether this is a v-device";
    };
  };

  config = mkMerge [
    {
      nix.package = pkgs.nixVersions.latest;

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      users.defaultUserShell = pkgs.bash;
      programs.bash = {
        enable = true;
        completion.enable = true;
      };

      networking = {
        firewall.enable = true;
        networkmanager.enable = true;
      };

      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };

      powerManagement.enable = true;

      boot.tmp.cleanOnBoot = true;

      nix.settings = {
        auto-optimise-store = true;
        download-buffer-size = 524288000;
      };

      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          # --keep-since: gcroots younger than this survive, so colmena
          # `--keep-result` roots for other hosts are not swept by the weekly
          # clean.
          extraArgs = "--keep 3 --keep-since 30d";
        };
      };

      security.polkit.enable = true;

      users.groups = {
        nixconfig = { };
      };

      # btop reads CPU power from the RAPL energy counter, which the kernel locks
      # to 0400 root. Relax it so power shows in btop on every host (re-opens the
      # RAPL power side-channel — accepted tradeoff fleet-wide). systemd-tmpfiles
      # silently skips the path on hosts without a RAPL node.
      systemd.tmpfiles.rules = [
        "Z /sys/class/powercap/intel-rapl:0/energy_uj 0444 root root - -"
      ];

      environment.variables.EDITOR = "nvim";

      environment.shellAliases = {
        vim = "nvim";
        ":q" = "exit";
        nrs = "nh os switch /etc/nixos";
        nrb = "nh os boot /etc/nixos";

        # Own the tree as the invoking user (not root): chmod() is owner-only, so tools that restore file mode
        # after writing (qwen-code) hit EPERM otherwise; 2775 lets nixconfig edit contents but never chmod.
        # $(id -un) keeps this fleet-safe (each host's human owner fixes to themselves).
        fix-nixos-git = "sudo chown -R $(id -un):nixconfig /etc/nixos && sudo chmod -R 2775 /etc/nixos && git config --global --add safe.directory /etc/nixos && git -C /etc/nixos config core.fileMode false";
      };

      services.interception-tools = {
        enable = true;
        plugins = with pkgs.interception-tools-plugins; [
          caps2esc
          dual-function-keys
        ];
        udevmonConfig = ''
          - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
            DEVICE:
              NAME: "(?!Wacom).*"
              EVENTS:
                EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
        '';
      };

      nixpkgs.config.allowUnfree = true;
    }

    (mkIf
      (config.systemOptions.deviceType.desktop.enable || config.systemOptions.deviceType.laptop.enable)
      {
        services.xserver.xkb = {
          layout = "us";
          variant = "";
        };

        services.printing.enable = true;
        services.avahi.enable = true;
        services.avahi.nssmdns4 = true;
        services.avahi.openFirewall = true;

        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };

        services.gnome.gnome-keyring.enable = true;

        security.rtkit.enable = true;
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = false;
        };

        boot.plymouth.enable = true;

        environment.shellAliases = {
          init-dev-env = "nix flake init -t github:ewtodd/dev-env --refresh";
          init-latex-env = "nix flake init -t github:ewtodd/latex-env --refresh";
          init-geant4-env = "nix flake init -t github:ewtodd/geant4-env --refresh";
          init-analysis-env = "nix flake init -t github:ewtodd/Analysis-Utilities --refresh";
          view-image = "kitten icat";
        };
      }
    )
  ];
}
