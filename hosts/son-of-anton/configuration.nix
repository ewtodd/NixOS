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
        # ~65GB at F16 — gpt-oss is natively MXFP4, so F16 keeps the experts at
        # native precision (effectively lossless) while the rest is f16. A "big"
        # model (co-resident with one small is fine). Switched from a local path
        # to -hf for consistency with the rest of the fleet; pre-staged into
        # /scratch/llama-cache (see dl-models.sh) so first load doesn't download.
        "gpt-oss-120b" = {
          hf = "unsloth/gpt-oss-120b-GGUF:F16";
          ctxSize = 131072;
          big = true;
          kvQuant = true;
        };
        # ~85GB weights at Q8_0 (near-lossless) — too large to pair with a small,
        # so `solo`. The default coding orchestrator (qwen-code). llama.cpp's auto
        # --parallel still serves multiple qwen-code sessions concurrently from
        # one unified KV cache, each at the full ctxSize, so no extra flags.
        "qwen3-coder-next" = {
          hf = "unsloth/Qwen3-Coder-Next-GGUF:Q8_0";
          ctxSize = 131072;
          solo = true;
          kvQuant = true;
          # Qwen3-Coder-Next recommended sampling (non-thinking model).
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
          # Qwen3-Instruct-2507 recommended sampling (non-thinking).
          extraFlags = [
            "--temp 0.7"
            "--top-p 0.8"
            "--top-k 20"
            "--min-p 0"
          ];
        };
        "qwen3.6-35b-a3b" = {
          hf = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q5_K_M";
          ctxSize = 131072;
          kvQuant = true;
          extraFlags = [
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
            # Qwen3.6 recommended sampling — thinking mode / general tasks (this
            # is LibreChat's default chat model, thinking on). presence-penalty
            # 1.5 is card-recommended (this family is repetition-prone in
            # thinking mode); complements DRY (token- vs sequence-level).
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
            "--presence-penalty 1.5"
          ];
        };
        # ~70GB weights — a "big" model.
        "qwen3.5-122b" = {
          hf = "unsloth/Qwen3.5-122B-A10B-GGUF:Q4_K_M";
          ctxSize = 131072;
          big = true;
          kvQuant = true;
          # Qwen3.5 recommended sampling — thinking mode / general (default on).
          extraFlags = [
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
            "--presence-penalty 1.5"
          ];
          # Vision: Qwen3.5 is a VL model; llama.cpp has the QWEN3VL projector,
          # but -hf doesn't auto-pull unsloth's mmproj, so fetch it explicitly.
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Qwen3.5-122B-A10B-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-aRr3G9QdQ3zkodmJ9YnEtJIjfXArM4Ge2PiX+frm5yU=";
          };
        };
        # === Experimental / testing models (parked on the 4TB /scratch). Most
        # are `solo`: too large at the chosen quant to co-reside with a small,
        # so each occupies the box alone (only bge-m3 rides alongside). ===

        # NVIDIA Nemotron 3 Super, 120B-A12B. ~84GB at UD-Q4_K_XL — solo.
        "nemotron-3-super-120b" = {
          hf = "unsloth/NVIDIA-Nemotron-3-Super-120B-A12B-GGUF:UD-Q4_K_XL";
          ctxSize = 131072;
          solo = true;
          kvQuant = true;
        };
        # Mistral Small 4, 119B (vision). ~99GB at UD-Q6_K — solo; ctx trimmed to
        # 64k to leave room for KV + the mmproj. -hf doesn't auto-pull the
        # projector, so fetch it explicitly (like qwen3.5-122b below).
        "mistral-small-4-119b" = {
          hf = "unsloth/Mistral-Small-4-119B-2603-GGUF:UD-Q6_K";
          ctxSize = 65536;
          solo = true;
          kvQuant = true;
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Mistral-Small-4-119B-2603-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-ivtTCWU3Zk4kigtKkkDCVne7D4qMtaWq080dYId2pOc=";
          };
        };
        # Mistral Medium 3.5, 128B (vision). ~88GB at Q5_K_M — solo; ctx 64k for
        # KV + the large 5.4GB projector. Q6 (+109GB) won't fit once the mmproj
        # and the always-resident title/embed models are accounted for. Inherits
        # Mistral's strict-alternation chat template (same jinja quirk as
        # mistral-small-4 on tool/MCP rounds).
        "mistral-medium-3.5-128b" = {
          hf = "unsloth/Mistral-Medium-3.5-128B-GGUF:Q5_K_M";
          ctxSize = 65536;
          solo = true;
          kvQuant = true;
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Mistral-Medium-3.5-128B-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-SU6ZP4AzDxcMpt1Dbbeo9ky8Vhf8zPPn0SVkZnEUsnI=";
          };
        };
        # StepFun Step-3.7-Flash (vision). ~94GB at Q3_K_M — solo; ctx 64k for KV
        # + the ~4GB mmproj. (Repo also ships an MTP draft for speculative decode;
        # not wired here yet.)
        "step-3.7-flash" = {
          hf = "stepfun-ai/Step-3.7-Flash-GGUF:Q3_K_M";
          ctxSize = 65536;
          solo = true;
          kvQuant = true;
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/stepfun-ai/Step-3.7-Flash-GGUF/resolve/main/mmproj-step3.7-flash-f16.gguf";
            hash = "sha256-XyXRH5IjXGloLKggr19MsSWuEULIwzwBjQs8kACi7Bw=";
          };
        };
        # MiniMax-M2.7 (uncensored merge). ~99GB at Q3_K_S — solo, and the only
        # quant that fits at all (Q4 exceeds 125GB RAM). Full 128k ctx is
        # aggressive: KV may not fit on long sessions — drop ctxSize if it OOMs.
        "minimax-m2.7" = {
          hf = "llmfan46/MiniMax-M2.7-ultra-uncensored-heretic-GGUF:Q3_K_S";
          ctxSize = 131072;
          solo = true;
          kvQuant = true;
        };
        # Tiny dedicated title/summary model, ALWAYS resident (a free-rider like
        # bge-m3) so LibreChat titling never evicts the main chat/coder model —
        # including the `solo` ones. ~0.6GB at Q8_0. It's a hybrid thinker, so
        # `--reasoning-budget 0` ends any thinking pass immediately (a title must
        # not trigger reasoning), plus Qwen3 non-thinking sampling.
        "qwen3-0.6b" = {
          hf = "unsloth/Qwen3-0.6B-GGUF:Q8_0";
          ctxSize = 8192;
          alwaysResident = true;
          kvQuant = true;
          extraFlags = [
            "--reasoning-budget 0"
            "--temp 0.7"
            "--top-p 0.8"
            "--top-k 20"
            "--min-p 0"
          ];
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
