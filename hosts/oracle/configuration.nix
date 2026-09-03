{ pkgs, ... }:
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
    graphics.asahi.enable = true;
    deviceType.server.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.binaryCache.consume = true;
    services.nodeExporter.enable = true;
    services.litellmProxy.enable = true;
    services.searxng = {
      enable = true;
      listenAddress = "0.0.0.0";
      openFirewall = true;
    };
    services.openWebUI.enable = true;
    services.llamaSwap = {
      enable = true;
      lanExpose = true;
      backend = "vulkan";
      embeddingModel = {
        hf = "ggml-org/bge-m3-Q8_0-GGUF";
        hfFile = "bge-m3-q8_0.gguf";
        pooling = "mean";
        ctxSize = 8192;
        gpuLayers = 0;
        port = 8082;
      };
      models = {
        "little-titles" = {
          hf = "acon96/Little-Titles-GGUF:Q8_0";
          alwaysResident = true;
          ctxSize = 4096;
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

  users.users.oracle = {
    isNormalUser = true;
    description = "oracle";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "oracle";
  system.stateVersion = "26.11";

  # 8 cores, 7 GB: default max-jobs=auto x cores=0 thrashes swap.
  nix.settings = {
    max-jobs = 2;
    cores = 4;
  };
}
