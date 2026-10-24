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
    graphics.intel.enable = true;
    deviceType.server.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.binaryCache.consume = true;
    services.nodeExporter.enable = true;
    services.scheduledReboot.enable = true;
    services.scheduledReboot.calendar = "Sun *-*-* 05:30:00";
    # Title generation, RAG embeddings and a chat model for maitred on mu, on the Arc A770M.
    services.llamaCpp = {
      enable = true;
      lanExpose = true;
      embeddingModel = {
        hf = "ggml-org/embeddinggemma-2-GGUF:Q8_0";
        port = 8082;
      };
      models = {
        "little-titles" = {
          hf = "acon96/Little-Titles-GGUF:Q8_0";
          port = 8080;
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
        "gemma-4-26b-a4b" = {
          hf = "google/gemma-4-26B-A4B-it-qat-q4_0-gguf:Q4_0";
          port = 8081;
          # Split between the slots: 32k each, the window maitred lists.
          ctxSize = 65536;
          parallel = 2;
          # Leaves ~0.4 GiB of VRAM beside titles and embeddings (measured from
          # fdinfo); fewer layers on the CPU overcommit the A770M and i915
          # evicts to RAM, stalling generation. llama.cpp's own fitting can't
          # catch it: Intel's Vulkan driver overstates free memory.
          nCpuMoe = 12;
          # No VRAM left for the vision encoder.
          mmprojDevice = "none";
          # Google's QAT repo ships no MTP head; ggml-org's works with these
          # weights (about half its drafts accepted).
          specType = "draft-mtp";
          specDraftHf = "ggml-org/gemma-4-26B-A4B-it-GGUF:Q8_0";
          # The model card's sampling; llama.cpp's defaults differ.
          extraFlags = [
            "--temp 1.0"
            "--top-k 64"
            "--top-p 0.95"
            "--min-p 0"
          ];
        };
      };
    };
    security.harden.enable = true;
  };

  users.users.fiona = {
    isNormalUser = true;
    description = "fiona";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "video"
      "render"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "fiona";
  system.stateVersion = "26.11";
}
