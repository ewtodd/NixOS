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
          # The Iris Xe iGPU (Vulkan1 is the A770M), leaving the A770M's VRAM
          # to Gemma and the embeddings.
          device = "Vulkan0";
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
        "gemma-4-12b" = {
          hf = "google/gemma-4-12B-it-qat-q4_0-gguf:Q4_0";
          port = 8081;
          # Split between the slots: 64k each, the window maitred lists and the
          # least son-of-anton accepts.
          ctxSize = 131072;
          parallel = 2;
          # No MTP draft: with the pinned llama.cpp, Gemma 4's MTP head stops
          # accepting drafts after the first prompt of ~4-7k tokens and stays
          # broken until restart, decoding slower than with no draft at all.
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

  hardware.graphics.extraPackages = [ pkgs.intel-compute-runtime ];

  # Development on the A770M stops and restarts the llama servers without sudo.
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.user == "fiona" &&
          /^llama-(server-[a-z0-9-]+|embeddings)\.service$/.test(action.lookup("unit"))) {
        return polkit.Result.YES;
      }
    });
  '';

  time.timeZone = "America/Chicago";
  networking.hostName = "fiona";
  system.stateVersion = "26.11";
}
