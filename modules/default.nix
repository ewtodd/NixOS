{
  config,
  lib,
  pkgs,
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
      services.binaryCache.serve = mkEnableOption "Serve the nix store as a binary cache via nix-serve, exposed through Caddy on server-nu";
      services.binaryCache.consume = mkEnableOption "Use the e-desktop binary cache as a substituter";
      services.router.enable = mkEnableOption "Act as a NAT router (WAN DHCP, LAN static, dnsmasq DHCP+DNS)";
      services.adguard.enable = mkEnableOption "AdGuard Home DNS ad-blocker (sits behind dnsmasq)";
      services.reverseProxy.enable = mkEnableOption "Caddy reverse proxy with auto-TLS";
      services.dyndns.enable = mkEnableOption "Namecheap dynamic DNS updater for ethanwtodd.com subdomains";
      services.bastion.enable = mkEnableOption "SSH bastion: hardened sshd + fail2ban + WoL helpers for inner hosts";
      services.wakeable.enable = mkEnableOption "Wake-on-LAN + initrd-SSH for remote unlock";
      services.nextcloud.enable = mkEnableOption "Nextcloud personal cloud (cloud.ethanwtodd.com)";
      services.ntfy.enable = mkEnableOption "ntfy push-notification server (ntfy.ethanwtodd.com)";
      services.prometheus.enable = mkEnableOption "Prometheus metrics server (scrapes node_exporters)";
      services.nodeExporter.enable = mkEnableOption "Prometheus node_exporter (system metrics on :9100)";
      services.grafana.enable = mkEnableOption "Grafana dashboards (status.ethanwtodd.com)";
      services.minecraft.enable = mkEnableOption "Public PaperMC Minecraft server (mc.ethanwtodd.com:25565)";

      services.llamaSwap.enable = mkEnableOption "llama.cpp model server via llama-swap (multi-model, hot-swapped)";

      services.llamaSwap.lanExpose = mkEnableOption ''
        expose llama-swap on the LAN (bind 0.0.0.0 + open the firewall). Off (the
        default) binds 127.0.0.1 only — correct for hosts where the sole consumer
        is local nvim FIM. Enable it on hosts another machine must reach (e.g.
        son-of-anton, served to the LiteLLM proxy on oracle)'';
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
        default = null;
        example = "/scratch/llama-cache";
        description = ''
          Directory for -hf model downloads (LLAMA_CACHE). Null uses a
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
              mlock = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether to include --mlock flag in llama-server command. Including breaks gemma models.
                '';
              };
              big = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Mark a chat model as "big" (too large to co-reside with
                  another big model on this host). The llama-swap matrix makes
                  big models mutually exclusive: at most one big is resident at a
                  time, and it may pair with at most one small model. Small
                  models (big = false) may all co-reside. Set on the ~100B-class
                  models so the solver never tries to keep two of them loaded.
                '';
              };
              solo = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Mark a chat model as "solo": exclusive against *every* other
                  chat model — never co-resident with a big OR a small (only the
                  always-on embedding model rides alongside it). Use for models
                  so large they can't even pair with a small (e.g. a Q8 ~85GB+
                  big), where the ordinary `big` lane's "big + one small" would
                  OOM. Implies the model occupies the host alone; takes
                  precedence over `big`.
                '';
              };
              alwaysResident = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Keep this chat model loaded at all times, co-resident with
                  whatever else is running — including `solo` models (which
                  otherwise admit only the embedding model alongside them). It's
                  ANDed into every matrix set, exactly like an embedding model,
                  and never participates in the big/small/solo lanes. Use for a
                  tiny utility model that must never be evicted — e.g. a dedicated
                  router model consumed by temple. Keep it small: it occupies RAM permanently.
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
              mmap = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to enable memory mapping (--mmap). When false, --no-mmap
                  is emitted. Enable for models that fail to load without mmap
                  (e.g. DeepSeek V4 Flash with mixed quantization).
                '';
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
                default = 256;
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
              extraFlags = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra llama-server flags.";
              };
            };
          }
        );
      };
      services.litellmProxy.enable = mkEnableOption "LiteLLM proxy + MCP gateway (containerized, son-of-anton)";
      services.searxng.enable = mkEnableOption "SearXNG metasearch (localhost; backs the LiteLLM searxng MCP)";
      services.templeServer.enable = mkEnableOption "temple renco agent server";

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
