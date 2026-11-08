{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  # maitred and SearXNG on the AI front host (mu).
  aiFront = config.systemOptions.aiFrontAddress;
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
  ];
  md2pdf = pkgs.writeShellApplication {
    name = "md2pdf";
    runtimeInputs = [
      pkgs.pandoc
      pkgs.typst
    ];
    text = ''
      if [ $# -lt 1 ]; then
        echo "usage: md2pdf <input.md> [output.pdf]" >&2
        exit 2
      fi
      out="''${2:-''${1%.*}.pdf}"
      TYPST_FONT_PATHS=${pkgs.dejavu_fonts}/share/fonts \
        pandoc "$1" -o "$out" \
          --pdf-engine=typst \
          -V mainfont="DejaVu Sans"
      echo "$out"
    '';
  };

  projectAgentTools = [
    config.nix.package
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
    pkgs.gawk
    pkgs.diffutils
    pkgs.less
    pkgs.curl
    pkgs.gnutar
    pkgs.gzip
    pkgs.python3
  ];
  projectAgents = {
    ricky = "soa-ricky";
    markets = "soa-markets";
  };

  soaPhysicsPython = inputs.son-of-anton.packages.${pkgs.system}.physics-runtime;

  # Mirrors niri's eOutputs (home-manager/desktopEnvironment/niri/settings/desktop.nix),
  # shifted right by 1080 so the leftmost x is 0. The greeter matches outputs by
  # connector or EDID make/model/serial; the rotated F22 has no serial, so its
  # make/model also matches the F22 on DP-2 and it needs its connector, which
  # changes between boots. Synced output settings are off for the same reason:
  # Sync records connector names from whichever boot ran it.
  greeterOutputsTemplate = (pkgs.formats.toml { }).generate "greeter.toml" {
    output = {
      use_synced_settings = false;
      layout = "@vertical@:0,0; Sceptre Tech Inc Sceptre O34:1080,0; Sceptre Tech Inc Sceptre F22 0x01010101:4520,0";
      transforms = "@vertical@:270";
    };
  };
  # Writes greeterOutputsTemplate to the greeter's greeter.toml with @vertical@
  # replaced by the rotated F22's current connector. If that monitor is not
  # connected within 5 s, it writes the template unchanged; the greeter skips
  # entries that match no output, and the other two still apply.
  greeterOutputsWriter = pkgs.writeShellScript "noctalia-greeter-outputs" ''
    PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gnused
      ]
    }
    vertical=""
    for _ in $(seq 10); do
      for edid in /sys/class/drm/card*-*/edid; do
        dir=''${edid%/edid}
        [ "$(cat "$dir/status")" = connected ] || continue
        grep -qa 'Sceptre F22' "$edid" || continue
        # EDID bytes 12-15: the numeric serial, set only on the DP-2 F22.
        [ "$(od -An -tx1 -j12 -N4 "$edid" | tr -d ' \n')" = 00000000 ] || continue
        name=''${dir##*/}
        vertical=''${name#card*-}
      done
      [ -n "$vertical" ] && break
      sleep 0.5
    done

    target=/var/lib/noctalia-greeter/greeter.toml
    if [ -n "$vertical" ]; then
      sed "s/@vertical@/$vertical/g" ${greeterOutputsTemplate} > "$target.tmp"
    else
      echo "rotated Sceptre F22 not connected; greeter.toml leaves it unplaced" >&2
      cp ${greeterOutputsTemplate} "$target.tmp"
    fi
    chmod 0644 "$target.tmp"
    mv -f "$target.tmp" "$target"
  '';
in
{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
    ./encrypted-volumes.nix
  ];

  systemOptions = {
    graphics.nvidia.enable = true;
    hardware.openRGB.enable = true;
    services.rgbLoad = {
      enable = true;
      backend = "openrgb";
      # The board and the GPU; drop to 1 when the GPU goes.
      expectedDevices = 2;
      # The GPU's lighting cannot be seen from outside the case.
      excludeDevices = [ "GeForce" ];
      # Only has to cover each header's chain; colours for LEDs past its end go nowhere.
      zoneSizes = {
        ARGB_V2_1 = 100;
        ARGB_V2_2 = 100;
        ARGB_V2_3 = 100;
      };
    };
    hardware.suzyqable.enable = true;
    hardware.xbox.enable = true;
    deviceType.desktop.enable = true;
    services.ssh.enable = true;
    services.binaryCache.serve = true;
    services.suspend-then-hibernate.enable = true;
    services.scheduledReboot = {
      enable = true;
      action = "poweroff";
      calendar = "Sun *-*-* 05:00:00";
    };
    services.wakeable.enable = true;
    services.nodeExporter.enable = true;
    services.wireview-monitor.enable = true;
    services.wireview-safety.enable = true;
    apps.docker.enable = true;
    security.harden.enable = true;
    owner.e.enable = true;
    services.backup.client = {
      enable = true;
      # ssh:// form: the shorthand cannot carry a port, and sshd here runs on 2222.
      repo = "ssh://borg@10.0.0.3:2222/tank/backups/e-workstation";
      passphraseFile = config.age.secrets.borg-passphrase.path;
      # /games excluded on purpose: 1.2 TiB of re-downloadable Steam content.
      paths = [
        "/home/e-play"
        "/home/e-work"
        "/labdata"
        "/var/lib"
        "/etc/nixos"
      ];
      # Boot-unlocked LUKS, always present; the guard stays because archiving
      # an empty mountpoint records the tree as deleted and ages out history.
      requiresMounts = [
        "/home/e-play"
        "/home/e-work"
        "/labdata"
      ];
      exclude = [
        "/home/*/.cache"
        "/home/*/.local/share/Trash"
        "/home/*/.local/share/Steam/steamapps/shadercache"
        "/home/*/.nv/ComputeCache"
        "/var/lib/systemd/coredump"
        # NFS from anton's tank, the same pool this repo lives on; its own
        # zfs snapshots cover it, and the SSD holds the originals.
        "/home/e-play/BIRDING"
        # Symlinks into /labdata stay links, so their trees are captured once
        # via the /labdata path, not twice.
      ];
    };
    services.nfs.client.mounts."/home/e-play/BIRDING" = "10.0.0.3:/tank/photos/BIRDING";
    services.son-of-anton = {
      enable = true;
      environmentFiles = [
        config.age.secrets.son-of-anton-env.path
        config.age.secrets.maitred-keys.path
      ];
      environment = {
        SIGNAL_HTTP_URL = "http://10.0.0.2:7583";
        SEARXNG_URL = "http://${aiFront}:8888/search";
        WEB_EXTRACT_URL = "http://${aiFront}:8890";
        SIGNAL_REACTIONS = "false";
      };
      # libnotify, nixfmt, deadnix and nix are module defaults now
      # (son-of-anton nixosModules.defaultExtras, 2026-11-06); extraPackages
      # stays for per-instance additions.
      instances = {
        work = {
          user = "e-work";
          son-of-antonHome = "/home/e-work/.son-of-anton";
          workingDirectory = "/home/e-work";
          environmentFiles = [ config.age.secrets.son-of-anton-work-env.path ];
          settings.gateway.single_user = true;
          settings.physics = {
            data_dirs = [ "/labdata/ANSG/YAP-Final" ];
            workspace_root = "/home/e-work/workspace-soa/runs";
          };
          settings.git = {
            author_name = "son-of-anton-bot";
            author_email = "307402699+son-of-anton-bot@users.noreply.github.com";
          };
        };
        play = {
          user = "e-play";
          son-of-antonHome = "/home/e-play/.son-of-anton";
          workingDirectory = "/home/e-play";
          environmentFiles = [ config.age.secrets.son-of-anton-play-env.path ];
          # Standing memory rules, encrypted (secrets/son-of-anton-play-rules.age).
          memoryRulesFile = config.age.secrets.son-of-anton-play-rules.path;
          settings.gateway.single_user = true;
          settings.git = {
            author_name = "son-of-anton-bot";
            author_email = "307402699+son-of-anton-bot@users.noreply.github.com";
          };
        };

        house = {
          user = "soa-house";
          createUser = true;
          managedAccount = false;
          stateDir = "/var/lib/soa-house";
          son-of-antonHome = "/var/lib/soa-house/.son-of-anton";
          workingDirectory = "/srv/household";
          environmentFiles = [ config.age.secrets.son-of-anton-house-env.path ];
          extraPackages = [
            md2pdf
            pkgs.pandoc
            pkgs.typst
          ];
          settings.gateway = {
            group_sessions_per_user = false;
          };
        };

        ricky = {
          user = "soa-ricky";
          createUser = true;
          managedAccount = false;
          stateDir = "/var/lib/soa-ricky";
          son-of-antonHome = "/var/lib/soa-ricky/.son-of-anton";
          workingDirectory = "/srv/ricky";
          environmentFiles = [ config.age.secrets.son-of-anton-ricky-env.path ];
          git.github = config.age.secrets.soa-ricky-github-key.path;
          settings.platforms.signal = {
            require_mention = true;
            history_backfill = true;
          };
          extraPackages = projectAgentTools;
          settings.gateway = {
            group_sessions_per_user = false;
          };
          # fiona's chat is always on (eklow); project work waits for the evening (son-of-anton's GPU).
          settings.relay.worker_hours = [
            20
            7
          ];
        };

        markets = {
          user = "soa-markets";
          createUser = true;
          managedAccount = false;
          stateDir = "/var/lib/soa-markets";
          son-of-antonHome = "/var/lib/soa-markets/.son-of-anton";
          workingDirectory = "/srv/markets";
          environmentFiles = [ config.age.secrets.son-of-anton-markets-env.path ];
          extraPackages = projectAgentTools;
          settings.platforms.signal = {
            require_mention = true;
            history_backfill = true;
          };
          settings.gateway = {
            group_sessions_per_user = false;
          };
          # fiona's chat is always on (eklow); project work waits for the evening (son-of-anton's GPU).
          settings.relay.worker_hours = [
            20
            7
          ];
        };
      };

      settings = {
        # Every chat is fiona: whatever eklow serves (maitred router.extra), son-of-anton's auto when eklow is down.
        gateway.model = "fiona";
        # Models fiona may not hand a worker (relay send's model): eklow is reached only through fiona's own
        # route and auto's fallback, and the DeepSeek API is not for workers. She is offered what maitred
        # reports as serving, less these.
        relay.hidden_models = [
          "fiona"
          "eklow/"
          "deepseek/"
        ];
        model = {
          # maitred's routed id: the strongest model son-of-anton is serving, kept per conversation where its
          # context is cached. "high" is each model's normal thinking (maitred maps it to xhigh on the Qwen pair).
          default = "auto";
          reasoning_effort = "high";
          provider = "custom";
          # Every model on the maitred backend is vision-capable, so attach
          # user images natively (image_url parts on the turn) instead of
          # pre-running vision_analyze and handing the model a lossy text
          # summary. auto image_input_mode reads this key.
          supports_vision = true;
        };
        cron = {
          model_drift_guard = false;
          # maitred's routed id: jobs run on ds4 or qwen, whichever mode is up, instead of failing when a
          # pinned model's mode is not loaded. Jobs with their own model pin keep it.
          model = "auto";
          model_provider = "custom";
        };
        # Sub-agents too, so they run whichever mode is up instead of failing while the Qwen pair is loaded.
        delegation.model = "auto";
        # Old model names a stored session or job may still pin: soa-d rewrites them at start and resolves them.
        models.renamed."unholy/glm53" = "unholy/glm5.3-flash";
        security.sensitive_path_exceptions = [ "/etc/nixos/" ];
        memory.rag = {
          enabled = true;
          base_url = "http://${aiFront}:4002/v1";
          model = "embed/embeddinggemma-2";
          api_key_env = "MAITRED_KEY_SOA";
          top_k = 5;
          # No per-refresh cap: eklow embeds ~20k tok/s, so a full rebuild (a model or prompt change) takes minutes
          # instead of ~40 hours at the default 200 chunks per 15-minute refresh.
          max_chunks_per_refresh = 0;
        };
        custom_providers.custom = {
          base_url = "http://${aiFront}:4002/v1";
          key_env = "MAITRED_KEY_SOA";
          # /model lists maitred's live /v1/models catalog (context windows and effort
          # vocabularies come from the same response); the models below are per-model
          # metadata only and no longer pin the picker.
          discover_models = true;
          models = {
            # The description is what fiona reads when she picks a worker's model (relay send's model).
            "auto".description =
              "maitred picks; outside qwen and dual mode it is the other model listed, except that it can fall back to eklow if that one goes down";
            # DSV4 efforts: none (chat mode), low, high (its default when thinking), max.
            "unholy/dsv4-flash" = {
              reasoning_effort = "high";
              reasoning_efforts = [
                "none"
                "low"
                "high"
                "max"
              ];
            };
            # GLM-5.3-Flash always thinks: low, high, max.
            "unholy/glm5.3-flash" = {
              reasoning_effort = "high";
              reasoning_efforts = [
                "low"
                "high"
                "max"
              ];
            };
            # Radiance's R9700 pair; its template's efforts (high/max clamp to medium/xhigh).
            "radiance/qwen3.8-27b" = {
              reasoning_effort = "xhigh";
              reasoning_efforts = [
                "none"
                "minimal"
                "low"
                "medium"
                "xhigh"
              ];
            };
            # The gufo fork on the Strix Halo iGPU, beside the 27B in llm-mode dual: DSV4's efforts.
            "gufo/deepseek-v4.1-flash" = {
              reasoning_effort = "high";
              reasoning_efforts = [
                "none"
                "low"
                "high"
                "max"
              ];
            };
            # gufo on the Strix Halo iGPU; its template's efforts.
            "gufo/qwen3.8-flash-next" = {
              reasoning_effort = "xhigh";
              reasoning_efforts = [
                "none"
                "low"
                "medium"
                "xhigh"
              ];
            };
            # eklow on fiona's A770M; Sage-A1.5 (Qwen3.6) thinks or not, and takes images (Qwen3-VL's
            # encoder).
            "eklow/sage-a1.5" = {
              reasoning_effort = "high";
              reasoning_efforts = [
                "none"
                "high"
              ];
            };
            "deepseek/deepseek-flash" = {
              reasoning_effort = "max";
              reasoning_efforts = [
                "low"
                "high"
                "max"
              ];
            };
          };
        };
        # The physics mode (son-of-anton problem run): a worker and a manager, both on auto, with model
        # code run in this runtime under bubblewrap. Limits are the defaults (8 work sessions, 400k tokens a
        # session, 3M a run, 8 hours); an instance that runs problems also sets data_dirs and workspace_root.
        physics = {
          model = "auto";
          python = "${soaPhysicsPython}/bin/python3";
        };
        web.backend = "searxng";
        mcp_servers.maitred = {
          url = "http://${aiFront}:4002/mcp";
          headers.Authorization = "Bearer \${MAITRED_KEY_SOA}";
          enabled = true;
        };
        auxiliary = {
          title_generation = {
            provider = "custom";
            model = "llama/little-titles";
            base_url = "http://${aiFront}:4002/v1";
            key_env = "MAITRED_KEY_SOA";
            prompt_style = "chat";
          };
          compaction = {
            provider = "custom";
            # For an auxiliary task son-of-anton reads "auto" as the session's own model, which is maitred's
            # "auto" unless the session is pinned: the strongest serving model whose window fits the whole
            # conversation (DS4's 512k whenever it is loaded).
            model = "auto";
            base_url = "http://${aiFront}:4002/v1";
            key_env = "MAITRED_KEY_SOA";
            reasoning_effort = "none"; # extraction, not reasoning
            timeout = 300; # local model over a large prompt; 120s default is tight
          };
        };

        platforms.signal = {
          typing_indicator = true;
          gateway_restart_notification = false;
        };
        terminal.home_mode = "cwd";
      };
    };
  };
  systemd.services = lib.mkMerge [
    (lib.mapAttrs' (
      name: user:
      lib.nameValuePair "son-of-anton-${name}" {
        environment = {
          GIT_AUTHOR_NAME = "son-of-anton (${name})";
          GIT_COMMITTER_NAME = "son-of-anton (${name})";
          GIT_AUTHOR_EMAIL = "${user}@e-workstation.invalid";
          GIT_COMMITTER_EMAIL = "${user}@e-workstation.invalid";
          NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
        };
      }
    ) projectAgents)
    {
      noctalia-greeter-outputs = {
        description = "Write the noctalia greeter's display layout for the current connectors";
        wantedBy = [ "graphical.target" ];
        before = [ "greetd.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = greeterOutputsWriter;
        };
      };
    }
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.settings = {
    substituters = [
      "https://cache.nixos-cuda.org"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
    keep-going = true;
    keep-outputs = true;
    log-lines = 200;
  };

  users.users.e-play = {
    isNormalUser = true;
    uid = 1003;
    description = "ethan-play";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "dialout"
      "video"
      "lp"
      "son-of-anton"
      "docker"
      "i2c"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  users.users.e-work = {
    isNormalUser = true;
    uid = 1001;
    description = "ethan-work";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "dialout"
      "video"
      "lp"
      "son-of-anton"
      "docker"
      "i2c"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  systemOptions.services.wakeable = {
    wiredInterface = "enp14s0";
    initrdNicModule = "r8169";
    initrdAuthorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOzNCr4bzaMgmGGlYuFvkt7yRi8xgQ1kaSwxvJCiSMf bastion-initrd-unlock"
    ];
  };

  networking.networkmanager = {
    connectionConfig."ethernet.cloned-mac-address" = lib.mkForce "permanent";
    settings.main.no-auto-default = "*";
    ensureProfiles.profiles.wired = {
      connection = {
        id = "wired";
        type = "ethernet";
        interface-name = "enp16s0";
        autoconnect = true;
      };
      ethernet.cloned-mac-address = "permanent";
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  # lifer's review app (e-play's user service) binds 127.0.0.1:8737 only, so no
  # firewall opening is needed.
  # lifer's home-manager module runs `pkgs.lifer`; home-manager uses the
  # system pkgs (useGlobalPkgs), so provide it here.
  nixpkgs.overlays = [
    (_: _: { lifer = inputs.lifer.packages.${pkgs.stdenv.hostPlatform.system}.default; })
  ];

  time.timeZone = "America/Chicago";
  networking.hostName = "e-workstation";
  system.stateVersion = "24.11";

}
