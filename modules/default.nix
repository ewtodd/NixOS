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

      apps.zoom.enable = mkEnableOption "Zoom";
      apps.remarkable.enable = mkEnableOption "Remarkable from wrapWine flake";
      apps.quickemu.enable = mkEnableOption "Quickemu";
      apps.docker.enable = mkEnableOption "Docker";

      services.ssh.enable = mkEnableOption "SSH with non-standard port";
      services.suspend-then-hibernate.enable = mkEnableOption "Suspend then hibernate";
      services.tailscale.enable = mkEnableOption "Literally just tailscale...";
      services.binaryCache.serve = mkEnableOption "Serve the nix store as a binary cache via nix-serve, exposed through Caddy on nu";
      services.binaryCache.consume = mkEnableOption "Use the e-desktop binary cache as a substituter";
      services.router.enable = mkEnableOption "Act as a NAT router (WAN DHCP, LAN static, dnsmasq DHCP+DNS)";
      services.adguard.enable = mkEnableOption "AdGuard Home DNS ad-blocker (sits behind dnsmasq)";
      services.reverseProxy.enable = mkEnableOption "Caddy reverse proxy with auto-TLS";
      services.dyndns.enable = mkEnableOption "Namecheap dynamic DNS updater for ethanwtodd.com subdomains";
      services.bastion.enable = mkEnableOption "SSH bastion: hardened sshd + fail2ban + WoL helpers for inner hosts";
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

      services.llamaSwap.enable = mkEnableOption "llama.cpp model server via llama-swap (multi-model, hot-swapped)";

      services.llamaSwap.lanExpose = mkEnableOption ''
        expose llama-swap on the LAN (bind 0.0.0.0 + open the firewall). Off (the
        default) binds 127.0.0.1 only — correct for hosts where the sole consumer
        is local nvim FIM. Enable it on hosts another machine must reach (e.g.
        son-of-anton, served to temple-server on son-of-anton)'';
      services.llamaSwap.port = mkOption {
        type = types.ints.positive;
        default = 8080;
        example = 1234;
      };
      services.llamaSwap.backend = mkOption {
        type = types.enum [
          "vulkan"
          "cuda"
          "rocm"
        ];
        default = "vulkan";
        description = "llama.cpp GPU backend: Vulkan (AMD RADV or Intel ANV) or CUDA (NVIDIA).";
      };
      services.llamaSwap.cacheDir = mkOption {
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
      services.llamaSwap.models = mkOption {
        default = { };
        description = "Models served via llama-swap; the module builds each llama-server command.";
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
              ctxSize = mkOption {
                type = types.ints.positive;
                default = 32768;
                description = "Context size (--ctx-size), sized for agentic/MCP use.";
              };
              ttl = mkOption {
                type = types.nullOr types.ints.positive;
                default = null;
                description = "Idle seconds before llama-swap unloads the model (frees VRAM). Null = keep loaded.";
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
              device = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Value for llama.cpp --device (e.g. "ROCm0", or a comma list
                  "ROCm0,ROCm1,ROCm2" to span several devices). Also drives
                  co-residency in the swap matrix: models sharing the exact
                  same value are mutual alternatives (they contend for the
                  same device), models on distinct devices may all be resident
                  together, and a comma list (multi-device) is treated as solo
                  — it can never co-reside with anything. Null lets llama.cpp
                  pick the device and gives the model its own exclusive slot.
                '';
              };
              solo = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Mark a model as "solo": it can never co-reside with any
                  other model. When requested, every other model (including
                  preloaded ones) is evicted, and it stays resident alone
                  until another model is requested. Use for models so large
                  they must occupy the whole host — e.g. a Q8 ~85GB+ model
                  that spans every GPU. Takes precedence over device-based
                  co-residency (a multi-device `device` list is auto-solo).
                '';
              };
              alwaysResident = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Keep this model loaded at all times. It is ANDed into every
                  swap-matrix set and preloaded at startup, so it is never
                  evicted — regardless of what else is running, including
                  solo models. Use only for tiny utility models that must
                  never go down (e.g. the router model consumed by temple).
                  Keep it small: it occupies RAM permanently.
                '';
              };
              preload = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Preload this model at llama-swap startup so it is warm
                  before the first request. Unlike `alwaysResident`, a
                  preloaded model CAN be evicted when another request (e.g. a
                  solo model) needs its resources.
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
              parallel = mkOption {
                type = types.nullOr types.ints.positive;
                default = null;
                description = ''
                  Value for --parallel (number of parallel request slots).
                  Set to null to omit the flag (llama-swap manages concurrency).
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
      services.llamaSwap.embeddingModel = mkOption {
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
              gpuLayers = mkOption {
                type = types.ints.positive;
                default = 99;
                description = "--n-gpu-layers for the embedding model.";
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
          Run a dedicated always-resident llama.cpp embedding server
          (llama-server --embedding) outside the swap matrix — embeddings
          must never be evicted. Serves Open WebUI RAG / temple memory
          recall (e.g. bge-m3).
        '';
      };
      services.litellmProxy.enable = mkEnableOption "LiteLLM OpenAI-compatible proxy (model routing for OpenAI-compatible clients like opencode)";
      services.templeServer.enable = mkEnableOption "temple renco agent server";
      services.temple-daemon = {
        enable = mkEnableOption "temple full-agent daemons — one per user on the workstation";
        userDaemons = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [
            "e-play"
            "e-work"
          ];
          description = "System usernames to run a full agent for.";
        };
        stateDir = mkOption {
          type = types.str;
          default = "/var/lib/temple";
        };
        modelEndpoints = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Model name to llama-swap endpoint mappings (with /v1).";
        };
        defaultModel = mkOption {
          type = types.str;
          default = "qwen3.6-35b-a3b";
        };
        simpleModel = mkOption {
          type = types.str;
          default = "qwen3.6-27b";
        };
        plannerModel = mkOption {
          type = types.str;
          default = "qwen3.6-35b-a3b";
        };
        executorModel = mkOption {
          type = types.str;
          default = "qwen3.6-27b";
        };
        reviewerModel = mkOption {
          type = types.str;
          default = "qwen3.6-35b-a3b";
        };
        researcherModel = mkOption {
          type = types.str;
          default = "qwen3.6-27b";
        };
        routerModel = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        titleModel = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        searxngUrl = mkOption {
          type = types.str;
          default = "http://127.0.0.1:8888/search";
          description = "SearXNG JSON API endpoint reachable from this host.";
        };
        allowedDirs = mkOption {
          type = types.listOf types.str;
          default = [
            "/etc/nixos"
            "/home"
          ];
        };
        defaultPermission = mkOption {
          type = types.str;
          default = "default";
        };
        authTokenFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Auth token file for Signal /verify (Signal-owning daemon).";
        };
        environmentFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "EnvironmentFile with secrets (e.g. OPENWEBUI_API_KEY).";
        };
        signal = {
          enable = mkEnableOption "Signal presence (one daemon owns the shared number)";
          owner = mkOption {
            type = types.str;
            default = "";
            description = "Username whose daemon owns the shared Signal number.";
          };
          socketAddr = mkOption {
            type = types.str;
            default = "127.0.0.1:7583";
            description = "signal-cli JSON-RPC socket.";
          };
          defaultRecipient = mkOption {
            type = types.str;
            default = "";
          };
          allowedSenders = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
        };
        openWebUI = {
          enable = mkEnableOption "Open WebUI memory bridge";
          baseUrl = mkOption {
            type = types.str;
            default = "http://127.0.0.1:8081";
          };
          apiKeyEnv = mkOption {
            type = types.str;
            default = "OPENWEBUI_API_KEY";
          };
        };
        authorizedKeys = mkOption {
          type = types.attrsOf (types.listOf types.str);
          default = { };
          description = "TUI client public keys per daemon user.";
        };
      };

      services.signal-cli.enable = mkEnableOption "signal-cli JSON-RPC daemon (Signal bot backend for temple)";
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
        description = "TCP socket address for the JSON-RPC daemon.";
      };
      services.signal-cli.dataDir = mkOption {
        type = types.path;
        default = "/var/lib/signal-cli";
        description = "State directory: keys, registration data.";
      };
      services.signal-cli.openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Open the JSON-RPC socket port in the firewall (needed if temple-server is on a different host).";
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
      services.rgbLoad.enable = mkEnableOption "load-reactive RGB lighting (drives color from max of CPU/GPU utilization)";
      services.rgbLoad.backend = mkOption {
        type = types.enum [
          "openrgb"
          "framework"
        ];
        default = "openrgb";
        description = "Lighting backend: the OpenRGB SDK server, or `framework_tool --rgbkbd`.";
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

      nix.settings = {
        auto-optimise-store = true;
        download-buffer-size = 524288000;
      };

      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep 3";
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

        # Own the tree as the invoking user (not root) so editors that restore
        # file mode after writing -- e.g. qwen-code's chmod-after-write -- don't
        # hit EPERM: chmod() is owner-only, and group-write (2775) lets the
        # nixconfig group edit *contents* but never chmod. $(id -un) keeps this
        # fleet-safe (each host's human owner fixes to themselves).
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
