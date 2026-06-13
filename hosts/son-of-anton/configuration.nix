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
    graphics.amd.enable = true;
    deviceType.server.enable = true;
    services.rgbLoad = {
      enable = true;
      backend = "framework";
    };
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.binaryCache.consume = true;
    services.nodeExporter.enable = true;
    services.litellmProxy.enable = true;
    services.searxng.enable = true;
    services.librechat.enable = true;
    services.ragApi.enable = true;
    services.llamaSwap = {
      enable = true;
      lanExpose = true; # bind 0.0.0.0 so the co-located LiteLLM proxy reaches it at 127.0.0.1:8080
      backend = "vulkan";
      cacheDir = "/scratch/llama-cache";
      models = {
        "gpt-oss-120b" = {
          path = "/scratch/llama.cpp/models--ggml-org--gpt-oss-120b-GGUF/snapshots/d932fcea62f83e088d8f076a2cd2d7eb02dfa682/gpt-oss-120b-mxfp4-00001-of-00003.gguf";
          ctxSize = 131072;
        };
        "qwen3-coder-next" = {
          hf = "unsloth/Qwen3-Coder-Next-GGUF:Q4_K_M";
          ctxSize = 131072;
        };
        "qwen3-30b-a3b" = {
          hf = "unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:Q5_K_M";
          ctxSize = 65536;
        };
        "qwen3.6-35b-a3b" = {
          hf = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q5_K_M";
          ctxSize = 131072;
          extraFlags = [
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
          ];
        };
        "qwen3.5-122b" = {
          hf = "unsloth/Qwen3.5-122B-A10B-GGUF:Q4_K_M";
          ctxSize = 131072;
          # Vision: Qwen3.5 is a VL model; llama.cpp has the QWEN3VL projector,
          # but -hf doesn't auto-pull unsloth's mmproj, so fetch it explicitly.
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Qwen3.5-122B-A10B-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-aRr3G9QdQ3zkodmJ9YnEtJIjfXArM4Ge2PiX+frm5yU=";
          };
        };
        # Embedding model backing LibreChat's RAG file search (via LiteLLM).
        # bge-m3 is a non-causal encoder: CLS pooling, and batch == ctx so a
        # full chunk embeds in one pass. The module's matrix lets it stay
        # resident alongside whichever chat model is loaded.
        "bge-m3" = {
          hf = "gpustack/bge-m3-GGUF:Q8_0";
          ctxSize = 8192;
          embedding = true;
          extraFlags = [
            "--pooling cls"
            "-b 8192"
            "-ub 8192"
          ];
        };
      };
    };
    services.scheduledReboot.enable = true;
    services.scheduledReboot.calendar = "*-*-* 04:45:00";
    security.harden.enable = true;
  };

  nixpkgs.config.rocmTargets = [ "gfx1151" ];

  users.users.son-of-anton = {
    isNormalUser = true;
    description = "son-of-anton";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "video"
      "render"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  systemd.tmpfiles.rules = [
    "d /scratch 0775 son-of-anton users - -"
  ];

  time.timeZone = "America/Chicago";
  networking.hostName = "son-of-anton";
  system.stateVersion = "25.11";
}
