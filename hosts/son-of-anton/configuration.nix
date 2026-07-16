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
    services.librechat.enable = true;
    services.searxng.enable = true;
    services.llamaSwap = {
      enable = true;
      lanExpose = true;
      backend = "vulkan";
      cacheDir = "/scratch/llama-cache";
      models = {
        "qwen3.6-35b-a3b-udq8" = {
          hf = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q8_K_XL";
          ctxSize = 262144;
          big = true;
          extraFlags = [
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
          ];

        };

        "qwen3.5-122b" = {
          hf = "unsloth/Qwen3.5-122B-A10B-MTP-GGUF:UD-Q5_K_XL";
          ctxSize = 262144;
          solo = true;
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

        "gemma-4-26b-a4b" = {
          hf = "unsloth/gemma-4-26B-A4B-it-GGUF:Q8_0";
          ctxSize = 262144;
          big = true;
          mlock = false;
          extraFlags = [
            "--temp 1.0"
            "--top-k 64"
            "--top-p 0.95"
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
          ];
        };

        "deepseek-v4-flash" = {
          hf = "unsloth/DeepSeek-V4-Flash-GGUF";
          ctxSize = 524288;
          solo = true;
          mlock = true;
          parallel = 1;
          flashAttn = "on";
          extraFlags = [
            "--temp 1.0"
            "--top-p 1.0"
            "--min-p 0.0"
          ];
        };

        "qwen3-4b-titles" = {
          hf = "unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-IQ3_XXS";
          ctxSize = 2048;
          alwaysResident = true;
          batchSize = 2048;
          ubatchSize = 2048;
          extraFlags = [
            "--temp 0.7"
            "--top-p 0.8"
            "--top-k 20"
            "--min-p 0"
          ];
        };
      };
    };
    security.harden.enable = true;
  };

  nixpkgs.config.rocmTargets = [
    "gfx1151"
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
