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
    ##### REMOVE WHEN nixpkgs PR #479283 LANDS #####
    ./hardware/ipu7
    ##### END REMOVE #####
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
      services.binaryCache.serve = mkEnableOption "Serve the nix store as a binary cache via nix-serve + Tailscale Funnel";
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
      services.llamaSwap.backend = mkOption {
        type = types.enum [
          "vulkan"
          "cuda"
        ];
        default = "vulkan";
        description = "llama.cpp GPU backend: Vulkan/RADV (AMD) or CUDA (NVIDIA).";
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
              extraFlags = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra llama-server flags.";
              };
            };
          }
        );
      };
      services.litellmProxy.enable = mkEnableOption "LiteLLM proxy + content-based classifier router (containerized, mu)";
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
      owner.e.enable = mkEnableOption "Whether this is an e-device. If it isn't then it must be a v-device!";
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
        fix-nixos-git = "sudo chown -R root:nixconfig /etc/nixos && sudo chmod -R 2775 /etc/nixos && git config --global --add safe.directory /etc/nixos && git -C /etc/nixos config core.fileMode false";
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
