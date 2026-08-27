{
  lib,
  pkgs,
  config,
  ...
}:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
  ];
  # md -> pdf for the household agent, as ONE command with no flags.
  #
  # pandoc's typst template renders `font: <mainfont>`, and typst rejects an
  # empty font list outright ("font fallback list must not be empty"), so a
  # bare `pandoc in.md -o out.pdf` fails. A systemd unit also has no
  # fontconfig, so typst finds no fonts at all unless TYPST_FONT_PATHS points
  # at some. Both are invocation details the agent would have to remember on
  # every call and would eventually get wrong — bake them in instead.
  #
  # typst rather than a TeX engine: self-contained and ~50 MB against several
  # GB for texlive, and this only needs to render documents.
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
      # One service per account, all on the one Signal number, separated by
      # Signal group id. The group ids and the sender allowlists live in the
      # per-instance agenix secrets below, NOT here: this repo is public and
      # both identify real people and real chats.
      #
      # Each secret carries, at minimum:
      #   SIGNAL_GROUP_ALLOWED_USERS=<that instance's group id>
      # and, where it must differ from the shared default:
      #   SIGNAL_ALLOWED_USERS=<comma-separated numbers>
      instances = {
        work = {
          user = "e-work";
          son-of-antonHome = "/home/e-work/.son-of-anton";
          workingDirectory = "/home/e-work";
          environmentFiles = [ config.age.secrets.son-of-anton-work-env.path ];
          model = "qwen3.5-122b-a10b";
        };
        play = {
          user = "e-play";
          son-of-antonHome = "/home/e-play/.son-of-anton";
          workingDirectory = "/home/e-play";
          environmentFiles = [ config.age.secrets.son-of-anton-play-env.path ];
          model = "qwen3.5-122b-a10b";
          # Physics and research live on the work account. Off here so their
          # keywords cannot pull a casual message into a one-shot loop.
          settings.router.modes = [ "standard" ];
        };
        # Multi-human group, so it gets its own service account rather than a
        # personal one: the agent acts for whoever speaks, and running it as
        # e-play would hand the other members e-play's home, keys, and git
        # identity. Its working directory is the only thing it can reach.
        #
        # Its secret also RE-DECLARES SIGNAL_ALLOWED_USERS with both people.
        # That override is scoped to this instance by file order, so the second
        # person is never authorized on work or play.
        house = {
          user = "soa-house";
          createUser = true;
          managedAccount = false;
          stateDir = "/var/lib/soa-house";
          son-of-antonHome = "/var/lib/soa-house/.son-of-anton";
          workingDirectory = "/srv/household";
          environmentFiles = [ config.age.secrets.son-of-anton-house-env.path ];
          model = "qwen3.5-122b-a10b";
          # Only this instance gets them: capability is per-account, and the
          # household agent acts for whoever speaks in a shared group.
          extraPackages = [
            md2pdf
            pkgs.pandoc
            pkgs.typst
          ];
          settings.router.modes = [ "standard" ];
        };
      };

      settings = {
        # The CLI's default. Each instance pins its own Signal model through
        # a channel_overrides entry on its group (see instances.*.model), so
        # one config.yaml per account serves both surfaces.
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
            "qwen3.5-122b-a10b" = {
              context_length = 262144;
            };
            "deepseek-v4-flash-full" = { };
            "deepseek-v4-flash" = { };
            "deepseek-v4-pro" = { };
          };
        };
        physics = {
          model = "deepseek-v4-flash-full";
          base_url = "http://10.0.0.6:4000/v1";
          api_key_env = "LITELLM_MASTER_KEY";
        };
        router = {
          enabled = true;
          simple_model = "qwen3.8-27b-instruct";
          default_model = "qwen3.5-122b-a10b";
          planner_model = "qwen3.8-27b-coding";
          executor_model = "qwen3.8-27b-coding";
          reviewer_model = "deepseek-v4-pro";
          researcher_model = "qwen3.8-27b-instruct";
        };
        web.backend = "searxng";
        auxiliary.title_generation = {
          provider = "custom";
          model = "supra-title";
          base_url = "http://10.0.0.6:4000/v1";
          key_env = "LITELLM_MASTER_KEY";
          prompt_style = "completion";
        };
        platforms.signal.typing_indicator = true;
        terminal.home_mode = "cwd";
      };
    };
  };

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
