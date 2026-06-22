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
    services.scheduledReboot.enable = true;
    services.scheduledReboot.calendar = "*-*-* 05:00:00";
    services.litellmProxy.enable = true;
    services.searxng.enable = true;
    services.librechat.enable = true;
    services.ragApi.enable = true;
    services.hermes.enable = true;
    services.llamaSwap = {
      enable = true;
      lanExpose = true;
      backend = "vulkan";
      egpu.enable = true;
      cacheDir = "/scratch/llama-cache";
      models = {
        "gpt-oss-120b" = {
          hf = "unsloth/gpt-oss-120b-GGUF:F16";
          ctxSize = 131072;
          big = true;
          kvQuant = true;
          extraFlags = [
            "--temp 1.0"
            "--top-p 1.0"
            "--top-k 0"
            "--min-p 0"
          ];
        };
        "qwen3-coder-next" = {
          hf = "unsloth/Qwen3-Coder-Next-GGUF:Q8_0";
          ctxSize = 262144;
          solo = true;
          kvQuant = true;
          extraFlags = [
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 40"
          ];
        };
        "qwen3-30b-a3b" = {
          hf = "unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:Q5_K_M";
          ctxSize = 65536;
          kvQuant = true;
          extraFlags = [
            "--temp 0.7"
            "--top-p 0.8"
            "--top-k 20"
            "--min-p 0"
          ];
        };
        "qwen3.6-35b-a3b-udq8" = {
          hf = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q8_K_XL";
          ctxSize = 262144;
          # Light enough at UD-Q8_K_XL to co-reside with the fast 30B (the auto
          # router's simple/general split) rather than evict it: `big` pairs one
          # big + one small. Smaller than gpt-oss, which already rides with 30B.
          big = true;
          kvQuant = true;
          extraFlags = [
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
            "--presence-penalty 1.5"
          ];
        };
        "qwen3.6-27b" = {
          hf = "unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q5_K_XL";
          ctxSize = 131072;
          # Dense -> eGPU (Vulkan0, ~6x APU bandwidth). UD-Q5_K_XL + mmproj +
          # draft head leaves ~4 GB headroom at 128k ctx with q8_0 KV.
          # Keep serverCtx in sync with qwen-code mkModel; eGPU is its own pool.
          gpu = "egpu";
          mlock = false; # weights live in VRAM; don't pin a host-RAM copy too
          kvQuant = true;
          extraFlags = [
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
            "--presence-penalty 1.5"
          ];
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Qwen3.6-27B-MTP-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-6s9hDR7kvV7QGXoHd92PT8647vonAJBnx9SWy2j73kU=";
          };
        };
        "qwen3.5-122b" = {
          hf = "unsloth/Qwen3.5-122B-A10B-MTP-GGUF:UD-Q5_K_XL";
          ctxSize = 262144;
          solo = true;
          kvQuant = true;
          extraFlags = [
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
            "--presence-penalty 1.5"
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
          ];
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Qwen3.5-122B-A10B-MTP-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-3kQFkw3G8ohUbidO5BlF9lH6NnOyrZBEwl/P/FuxxW0=";
          };
        };

        "gemma-4-31b" = {
          hf = "unsloth/gemma-4-31B-it-GGUF:UD-Q5_K_XL";
          ctxSize = 65536;
          # Dense -> eGPU (Vulkan0). UD-Q5_K_XL + vision projector fills most
          # of the 32 GB card at 64k ctx; drop ctxSize if vision goes tight.
          gpu = "egpu";
          mlock = false; # mlock breaks gemma loads regardless
          kvQuant = true;
          extraFlags = [
            "--temp 1.0"
            "--top-k 64"
            "--top-p 0.95"
          ];
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/gemma-4-31B-it-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-btzKIoITwo01Z6NdIvhJ7qUtg2CHUJOFGVmt9dLycOs=";
          };
        };
        "gemma-4-26b-a4b" = {
          hf = "unsloth/gemma-4-26B-A4B-it-GGUF:Q8_0";
          ctxSize = 131072;
          big = true;
          mlock = false;
          kvQuant = true;
          extraFlags = [
            "--temp 1.0"
            "--top-k 64"
            "--top-p 0.95"
          ];
        };
        # The always-on Hermes orchestrator brain (son-of-anton). alwaysResident
        # so it rides alongside whatever big delegation model is loaded. Gemma 4
        # thinks by default -- keep it (routing quality depends on it).
        "gemma-4-e4b-q6" = {
          hf = "unsloth/gemma-4-E4B-it-GGUF:Q6_K";
          ctxSize = 32768;
          mlock = false;
          kvQuant = true;
          alwaysResident = true;
          extraFlags = [
            "--temp 1.0"
            "--top-k 64"
            "--top-p 0.95"
          ];
        };

        "nemotron-3-super-120b" = {
          hf = "unsloth/NVIDIA-Nemotron-3-Super-120B-A12B-GGUF:UD-Q4_K_XL";
          ctxSize = 262144;
          solo = true;
          kvQuant = true;
          extraFlags = [
            "--temp 1.0"
            "--top-p 0.95"
          ];
        };
        "mistral-small-4-119b" = {
          hf = "unsloth/Mistral-Small-4-119B-2603-GGUF:UD-Q6_K";
          ctxSize = 65536;
          solo = true;
          kvQuant = true;
          extraFlags = [
            "--temp 0.7"
            "--top-p 1.0"
          ];
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Mistral-Small-4-119B-2603-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-ivtTCWU3Zk4kigtKkkDCVne7D4qMtaWq080dYId2pOc=";
          };
        };
        "mistral-medium-3.5-128b" = {
          hf = "unsloth/Mistral-Medium-3.5-128B-GGUF:Q5_K_M";
          ctxSize = 65536;
          solo = true;
          kvQuant = true;
          extraFlags = [
            "--temp 0.7"
            "--top-p 1.0"
          ];
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Mistral-Medium-3.5-128B-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-SU6ZP4AzDxcMpt1Dbbeo9ky8Vhf8zPPn0SVkZnEUsnI=";
          };
        };
        "step-3.7-flash" = {
          hf = "stepfun-ai/Step-3.7-Flash-GGUF:Q3_K_M";
          ctxSize = 65536;
          solo = true;
          mlock = false;
          kvQuant = true;
          extraFlags = [
            "--model-draft ${
              pkgs.fetchurl {
                url = "https://huggingface.co/stepfun-ai/Step-3.7-Flash-GGUF/resolve/main/Step3.7-flash-mtp-Q8_0.gguf";
                hash = "sha256-RpqBZnps1th6hdUB1XFV/ZDO5a9wEP0onFFpiBdj/Vc=";
              }
            }"
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
            "--temp 1.0"
            "--top-p 0.95"
          ];
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/stepfun-ai/Step-3.7-Flash-GGUF/resolve/main/mmproj-step3.7-flash-f16.gguf";
            hash = "sha256-XyXRH5IjXGloLKggr19MsSWuEULIwzwBjQs8kACi7Bw=";
          };
        };
        "minimax-m2.7" = {
          hf = "llmfan46/MiniMax-M2.7-ultra-uncensored-heretic-GGUF:Q3_K_S";
          ctxSize = 131072;
          solo = true;
          kvQuant = true;
          extraFlags = [
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 40"
          ];
        };
        "qwen3-4b-titles" = {
          hf = "unsloth/Qwen3-4B-Instruct-2507-GGUF:Q5_K_M";
          ctxSize = 8192;
          alwaysResident = true;
          kvQuant = true;
          extraFlags = [
            "--temp 0.7"
            "--top-p 0.8"
            "--top-k 20"
            "--min-p 0"
          ];
        };
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
    security.harden.enable = true;
  };

  nixpkgs.config.rocmTargets = [
    "gfx1151"
    "gfx1201"
  ];

  users.users.son-of-anton = {
    isNormalUser = true;
    description = "son-of-anton";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "video"
      "render"
      "hermes"
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
