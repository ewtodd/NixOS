{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
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

  soaPkg = inputs.son-of-anton.packages.${pkgs.system}.default;
  soaPhysicsPython = inputs.son-of-anton.packages.${pkgs.system}.physics-runtime;
  bridgeEnabled = true;

  bridgePath = [
    pkgs.bashInteractive
    pkgs.coreutils
    pkgs.git
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
  ]
  ++ projectAgentTools;
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
      calendar = "Sun,Wed *-*-* 05:00:00";
    };
    services.wakeable.enable = true;
    services.nodeExporter.enable = true;
    services.wireview-monitor.enable = true;
    services.wireview-safety.enable = true;
    apps.docker.enable = true;
    security.harden.enable = true;
    owner.e.enable = true;
    services.son-of-anton = {
      enable = true;
      environmentFiles = [ config.age.secrets.son-of-anton-env.path ];
      environment = {
        SIGNAL_HTTP_URL = "http://10.0.0.2:7583";
        SEARXNG_URL = "http://10.0.0.6:8888/search";
        SIGNAL_REACTIONS = "false";
      };
      instances = {
        work = {
          user = "e-work";
          son-of-antonHome = "/home/e-work/.son-of-anton";
          workingDirectory = "/home/e-work";
          environmentFiles = [ config.age.secrets.son-of-anton-work-env.path ];
          model = "qwen3.8-27b-coding";
          settings.physics = {
            data_dirs = [ "/home/e-work/LabData/ANSG/YAP-Final" ];
            workspace_root = "/home/e-work/workspace-soa/runs";
          };
        };
        play = {
          user = "e-play";
          son-of-antonHome = "/home/e-play/.son-of-anton";
          workingDirectory = "/home/e-play";
          environmentFiles = [ config.age.secrets.son-of-anton-play-env.path ];
          model = "qwen3.8-27b-coding";
          settings = {
            router.modes = [ "standard" ];
            platforms.signal.gateway_restart_notification = true;
            mcp_servers = lib.mapAttrs (name: _: {
              command = "${pkgs.socat}/bin/socat";
              args = [
                "STDIO"
                "UNIX-CONNECT:/run/soa-${name}-mcp.sock"
              ];
              enabled = bridgeEnabled;
            }) projectAgents;
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
          model = "qwen3.8-27b-coding";
          extraPackages = [
            md2pdf
            pkgs.pandoc
            pkgs.typst
          ];
          settings.router.modes = [ "standard" ];
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
          model = "qwen3.8-27b-coding";
          settings = {
            model.default = "qwen3.8-27b-coding";
          };
          extraPackages = projectAgentTools;
          settings.router.modes = [ "standard" ];
          settings.gateway = {
            group_sessions_per_user = false;
            active_hours = [
              20
              7
            ];
            inactive_message =
              "Off the clock until 8pm - son-of-anton is doing real work!"
              + "Your message is saved; I'll ask about it tonight.";
          };
        };

        markets = {
          user = "soa-markets";
          createUser = true;
          managedAccount = false;
          stateDir = "/var/lib/soa-markets";
          son-of-antonHome = "/var/lib/soa-markets/.son-of-anton";
          workingDirectory = "/srv/markets";
          environmentFiles = [ config.age.secrets.son-of-anton-markets-env.path ];
          model = "qwen3.8-27b-coding";
          settings = {
            model.default = "qwen3.8-27b-coding";
          };
          extraPackages = projectAgentTools;
          settings.router.modes = [ "standard" ];
          settings.platforms.signal = {
            require_mention = true;
            history_backfill = true;
          };
          settings.gateway = {
            group_sessions_per_user = false;
            active_hours = [
              20
              7
            ];
            inactive_message =
              "Off the clock until 8pm - son-of-anton is doing real work!"
              + "Your message is saved; I'll ask about it tonight.";
          };
        };
      };

      settings = {
        model = {
          default = "qwen3.8-27b-coding";
          provider = "custom";
        };
        custom_providers.custom = {
          base_url = "http://10.0.0.6:4000/v1";
          key_env = "LITELLM_MASTER_KEY";
          models = {
            "qwen3.8-27b-coding" = {
              context_length = 262144;
            };
            "qwen3.8-27b-instruct" = {
              context_length = 262144;
            };
            "deepseek-v4-flash-local" = {
              context_length = 131072;
            };
            "deepseek-v4-api" = { };
          };
        };
        physics = {
          # Both roles on Qwen3.8-27B, which the vLLM pool serves under two
          # sampling profiles of the same weights — so switching between them
          # costs nothing.
          #
          # `-coding` is the THINKING profile (temperature 1.0, no
          # enable_thinking=false); `-instruct` sets enable_thinking=false. That
          # is the right way round for these two jobs and was previously the
          # wrong way round: the reasoning role ran on deepseek-v4-flash-local,
          # whose rounds took ~15 minutes each, while the script writers ran on
          # the thinking profile and spent 40-55k output tokens and nine to
          # twenty minutes reasoning before emitting a 19 KB script.
          model = "qwen3.8-27b-coding";
          coder_model = "qwen3.8-27b-instruct";
          # Qwen3.8's default effort is "xhigh". Measured on a script-writing
          # prompt with a 24k budget: xhigh spent 628 s and 80,366 characters
          # reasoning and emitted no script at all; medium took 120 s and
          # produced one; low took 93 s. Medium keeps the reasoning that the
          # Manager's judgment work is for without the default's collapse.
          #
          # Safe to set globally even though coder_model has thinking
          # disabled: measured against qwen3.8-27b-instruct at low, medium and
          # xhigh, its reasoning channel stays empty — enable_thinking=false
          # wins, and the parameter is inert.
          reasoning_effort = "medium";
          # Per-role overrides beat both. The critic is exactly where a slow,
          # knowledgeable model belongs: one call per iteration against a
          # Manager that spends five or six rounds and several sub-agent
          # dispatches, so ds4's latency is a rounding error — and judging
          # whether a calibration anchor is quenched or a classifier is
          # training on the label is world knowledge, not code.
          agent_models = {
            critic = "deepseek-v4-flash-local";
          };
          base_url = "http://10.0.0.6:4000/v1";
          api_key_env = "LITELLM_MASTER_KEY";
          python = "${soaPhysicsPython}/bin/python3";
          sandbox = "bwrap";
          # Seconds one model-authored script may run for. The 60 s default
          # came from a scaffold built for symbolic work, where a script that
          # runs a minute is stuck. Here the files are multi-GB and a full
          # load_tree_data does not finish in a minute — and the agent reads a
          # timeout as "wrong approach", so it retries the same script rather
          # than the smaller read that would have worked.
          script_timeout = 900;
          # Physics mode has no wall-clock or cost gate, so this is the only
          # ceiling on an unattended run.
          max_iterations = 20;
          mcp = {
            server = "oracle";
            # Per role, and named tools rather than a server prefix: "arxiv"
            # matches all nineteen tools that server exposes, including topic
            # watches, alert checks, a reindexer and four LaTeX-source readers
            # — a human's library workflow, and nineteen schemas in front of an
            # agent whose budget is fifteen calls an iteration.
            roles = {
              # Reading tools only: find, triage, fetch, read, search within.
              # No context7 — the Manager writes the brief, not the code.
              manager = [
                "arxiv-search_papers"
                "arxiv-get_abstract"
                "arxiv-download_paper"
                "arxiv-read_paper"
                "arxiv-search_paper_text"
              ];
              # The one that writes the script gets the API docs, and nothing
              # else. Guessing at PyROOT is this loop's dominant failure.
              subagent = [ "context7" ];
            };
          };
        };
        router = {
          enabled = true;
          simple_model = "qwen3.8-27b-instruct";
          default_model = "qwen3.8-27b-coding";
          planner_model = "qwen3.8-27b-coding";
          executor_model = "qwen3.8-27b-coding";
          reviewer_model = "deepseek-v4-flash-local";
          researcher_model = "deepseek-v4-flash-local";
        };
        web.backend = "searxng";
        mcp_servers.oracle = {
          url = "http://10.0.0.6:4000/mcp/";
          headers.Authorization = "Bearer \${LITELLM_MASTER_KEY}";
          enabled = true;
        };
        auxiliary.title_generation = {
          provider = "custom";
          model = "supra-title";
          base_url = "http://10.0.0.6:4000/v1";
          key_env = "LITELLM_MASTER_KEY";
          prompt_style = "completion";
        };
        platforms.signal.typing_indicator = true;
        platforms.signal.gateway_restart_notification = false;
        auxiliary.background_review.schedule = "daily";
        terminal.home_mode = "cwd";
      };
    };
  };
  users.groups.soa-bridge = { };

  systemd.sockets = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "soa-${name}-mcp" {
      description = "MCP bridge socket for the ${name} son-of-anton instance";
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = "/run/soa-${name}-mcp.sock";
        SocketMode = "0660";
        SocketGroup = "soa-bridge";
        # One `mcp serve` per connection, with the connection as its stdio.
        Accept = "yes";
      };
    }
  ) projectAgents;

  systemd.services = lib.mkMerge [
    (lib.mapAttrs' (
      name: user:
      lib.nameValuePair "son-of-anton-${name}" {
        environment = {
          GIT_AUTHOR_NAME = "son-of-anton (${name})";
          GIT_COMMITTER_NAME = "son-of-anton (${name})";
          GIT_AUTHOR_EMAIL = "${user}@e-desktop.invalid";
          GIT_COMMITTER_EMAIL = "${user}@e-desktop.invalid";
          NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
        };
      }
    ) projectAgents)

    (lib.mapAttrs' (
      name: user:
      lib.nameValuePair "soa-${name}-mcp@" {
        description = "MCP bridge for the ${name} son-of-anton instance (connection %i)";
        path = bridgePath;
        environment = {
          HOME = "/var/lib/soa-${name}";
          SON_OF_ANTON_HOME = "/var/lib/soa-${name}/.son-of-anton";
          NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
        };
        serviceConfig = {
          User = user;
          Group = "son-of-anton";
          ExecStart = "${soaPkg}/bin/son-of-anton mcp serve";
          StandardInput = "socket";
          StandardOutput = "socket";
          StandardError = "journal";
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          NoNewPrivileges = true;
          UMask = "0007";
          ReadWritePaths = [
            "/var/lib/soa-${name}"
            "/srv/${name}"
          ];
        };
      }
    ) projectAgents)

    {
      son-of-anton-play.serviceConfig.SupplementaryGroups = [ "soa-bridge" ];
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
  };

  users.users.e-play = {
    isNormalUser = true;
    description = "ethan-play";
    extraGroups = [
      "nixconfig"
      "soa-bridge"
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
    wiredInterface = "enp16s0";
    initrdNicModule = "r8169";
    initrdAuthorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOzNCr4bzaMgmGGlYuFvkt7yRi8xgQ1kaSwxvJCiSMf bastion-initrd-unlock"
    ];
  };

  services.protonmail-bridge = {
    enable = true;
    path = with pkgs; [
      pass
      gnome-keyring
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

  time.timeZone = "America/Chicago";
  networking.hostName = "e-desktop";
  system.stateVersion = "24.11";

}
