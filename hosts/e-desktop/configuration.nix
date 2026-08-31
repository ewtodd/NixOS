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
          model = "deepseek-v4-api";
          base_url = "http://10.0.0.6:4000/v1";
          api_key_env = "LITELLM_MASTER_KEY";
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
        # Oracle's LiteLLM aggregates fetch, searxng, nixos, arxiv, and
        # context7 and re-exposes them as one MCP endpoint. Shared rather than
        # per-instance: these are read-only research tools, and the alternative
        # is five copies of the same five servers, one per account.
        #
        # ${LITELLM_MASTER_KEY} is interpolated from the instance's .env at
        # read time -- the same key these instances already use for inference,
        # so the gateway needs no credential of its own. `web.backend` stays
        # searxng: that is the agent's own search path and does not go through
        # here.
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
        # Restart/startup notifications are operator-only: off for every
        # instance, then re-enabled by instances.play.settings above.
        platforms.signal.gateway_restart_notification = false;
        # Self-improvement review once a day, overnight, instead of every
        # N turns/tool-iterations (auxiliary.background_review.schedule).
        auxiliary.background_review.schedule = "daily";
        terminal.home_mode = "cwd";
      };
    };
  };

  # ── e-play reaching the project agents ───────────────────────────────
  # `son-of-anton mcp serve` exposes one instance's conversations to another
  # agent, but only over stdio: there is no port to connect to and no flag
  # that gives it one. Crossing accounts therefore needs something that hands
  # a connection to a process running as the OTHER user as its stdin and
  # stdout, which is exactly socket activation with Accept=yes. sudo would be
  # the obvious alternative and cannot work here at all: every gateway unit
  # runs NoNewPrivileges=true, which refuses setuid outright.
  #
  # The hole is deliberate and one-way. Talking to one of these agents means
  # asking it to take a turn, and its turns run commands in its own working
  # directory -- so this grants e-play reach into ricky and markets, and
  # grants ricky and markets no reach into e-play, house, or each other. They
  # are never given the soa-bridge group, and each socket is 0660
  # root:soa-bridge.
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
    # Per-instance unit environment for the two project gateways.
    # `services.son-of-anton.environment` is shared by every instance (it
    # lands in each .env) and the per-instance escape hatch is an
    # environmentFile, which is agenix-encrypted. Neither fits a non-secret
    # value that must differ per instance, so it comes in through the unit.
    #
    # Git identity as env vars rather than a .gitconfig: git reads these
    # directly, and there is no home to drop a config file in that the agent
    # could not also rewrite. NIX_SSL_CERT_FILE because these two run
    # `nix develop`, and a systemd unit gets none of the login profile that
    # normally points nix at the CA bundle.
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

    # The far end of the bridge, one template unit per project agent: it runs
    # as that instance's account, in that instance's SON_OF_ANTON_HOME, so a
    # question arriving over the socket lands in the same session store and
    # the same memory as the Signal group -- not in a fresh agent that merely
    # shares the directory.
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
          # The same reach as this instance's gateway and no more: its own
          # state and its own working directory.
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
      # The play gateway runs as e-play but with Group=son-of-anton, so it
      # carries none of e-play's own groups. Without this it cannot open the
      # 0660 root:soa-bridge sockets, and its two mcp_servers would sit there
      # failing to connect.
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
      # Reaches the ricky and markets MCP bridge sockets from a terminal,
      # the same way this account's gateway does through SupplementaryGroups.
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
    # Secret-service backends for Proton Bridge's headless credential storage.
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
