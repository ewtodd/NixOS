{ ... }:
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
    services.binaryCache.consume = true;
    services.nodeExporter.enable = true;
    services.llamaSwap = {
      enable = true;
      backend = "vulkan"; # Strix Halo iGPU via RADV
      cacheDir = "/scratch/llama-cache";
      models = {
        # big-moe / orchestrator default. Local on the SN5100 (/scratch), HF-cache
        # layout; -m points at the first shard, llama.cpp loads the rest beside it.
        # (Snapshot hash changes if re-downloaded.)
        "gpt-oss-120b" = {
          path = "/scratch/llama.cpp/models--ggml-org--gpt-oss-120b-GGUF/snapshots/d932fcea62f83e088d8f076a2cd2d7eb02dfa682/gpt-oss-120b-mxfp4-00001-of-00003.gguf";
          ctxSize = 65536;
        };
        # smart-coder: 80B-A3B coder brain at A3B decode speed (~42 t/s).
        "qwen3-coder-next" = {
          hf = "unsloth/Qwen3-Coder-Next-GGUF:Q4_K_M";
          ctxSize = 65536;
        };
        # ultra-fast: general 30B-A3B, ~100 t/s; the snappy non-coding tier.
        "qwen3-30b-a3b" = {
          hf = "unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:Q5_K_M";
          ctxSize = 65536;
        };
        # orchestrator alternate, name-selectable for a head-to-head vs gpt-oss.
        # (Qwen3.6-122B-A10B has no GGUF yet; this is the 3.5 of the same shape.)
        "qwen3.5-122b" = {
          hf = "unsloth/Qwen3.5-122B-A10B-GGUF:Q4_K_M";
          ctxSize = 65536;
        };
        # capability experiment, name-selectable only (~109GB Q3, loads alone).
        "minimax-m2.5" = {
          hf = "unsloth/MiniMax-M2.5-GGUF:Q3_K_M";
          ctxSize = 32768;
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
