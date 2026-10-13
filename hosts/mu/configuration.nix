{ config, pkgs, ... }:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
  ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    deviceType.server.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.binaryCache.consume = true;
    services.bastion.enable = true;
    # e-desktop powers off Sun and Wed at 05:00 (plus up to 2 minutes of
    # jitter); leave the shutdown room to finish, then wake it back up.
    services.bastion.wakeCalendar = "Sun,Wed *-*-* 05:10:00";
    services.nextcloud.enable = true;
    services.minecraft.enable = true;
    services.nodeExporter.enable = true;
    services.scheduledReboot.enable = true;
    services.scheduledReboot.calendar = "*-*-* 04:30:00";
    # Signal bot backend for the son-of-anton gateway on e-desktop (HTTP
    # JSON-RPC mode — the interface the gateway's Signal adapter speaks).
    # Runs on x86_64; the gateway reaches it over the LAN.
    services.signal-cli = {
      enable = true;
      environmentFile = config.age.secrets.signal-cli-env.path;
      socketAddr = "0.0.0.0:7583";
      openFirewall = true;
    };

    # The AI front, moved here from oracle (systemOptions.aiFrontAddress points the clients and nu's
    # reverse proxy at this host): maitred (/v1 and /mcp on :4002, with Bifrost's keys and model ids),
    # Open WebUI, SearXNG, and llama-swap serving the title model and the RAG embeddings on the CPU.
    services.maitred = {
      enable = true;
      environmentFiles = [
        config.age.secrets.bifrost-env.path
        config.age.secrets.bifrost-keys.path
      ];
    };
    services.searxng = {
      enable = true;
      listenAddress = "0.0.0.0";
      openFirewall = true;
    };
    services.openWebUI.enable = true;
    services.llamaSwap = {
      enable = true;
      lanExpose = true;
      backend = "cpu";
      embeddingModel = {
        hf = "ggml-org/bge-m3-Q8_0-GGUF";
        hfFile = "bge-m3-q8_0.gguf";
        # bge-m3's dense embedding is the CLS vector; mean pooling compresses
        # cosine scores into a narrow band where unrelated text still scores ~0.5.
        pooling = "cls";
        ctxSize = 8192;
        gpuLayers = 0;
        port = 8082;
      };
      models = {
        "little-titles" = {
          hf = "acon96/Little-Titles-GGUF:Q8_0";
          alwaysResident = true;
          ctxSize = 4096;
          gpuLayers = "0";
          chatTemplateFile = pkgs.writeText "little-titles.jinja" ''
            {%- set ns = namespace(system="Generate a short title describing the following user request.", user="") -%}
            {%- for m in messages -%}
              {%- if m.role == "system" -%}
                {%- set ns.system = m.content -%}
              {%- elif m.role == "user" -%}
                {%- set ns.user = ns.user + ("\n" if ns.user else "") + m.content -%}
              {%- endif -%}
            {%- endfor -%}
            {{- "<|im_start|>system\n" + ns.system + "<|im_end|>\n" -}}
            {{- "<|im_start|>user\n" + ns.user + "<|im_end|>\n" -}}
            {%- if add_generation_prompt -%}{{- "<|im_start|>assistant\n" -}}{%- endif -%}
          '';
        };
      };
    };
    security.harden.enable = true;
  };

  users.users.mu = {
    isNormalUser = true;
    description = "mu";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "mu";
  system.stateVersion = "25.11";
}
