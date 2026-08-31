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
    ./environment.nix
    ./extra-packages.nix
    ./hardware-configuration.nix
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
    services.scheduledReboot.calendar = "Sun *-*-* 05:00:00";
    services.vllm = {
      enable = true;
      lanExpose = true;
      model = "Qwen/Qwen3.8-27B-FP8";
      devices = "0,1";
      tensorParallelSize = 2;
      maxModelLen = 262144;
      kvCacheDtype = "fp8";
      maxNumSeqs = 4;
      gpuMemoryUtilization = 0.90;
      enforceEager = true;
      mtp = true;
      mtpTokens = 3;
      port = 8100;
      toolCallParser = "qwen3_xml";
      reasoningParser = "qwen3";
      languageModelOnly = false;
    };
    services.ds4 = {
      enable = true;
      lanExpose = true;
      model = "/scratch/llama-cache/models--antirez--deepseek-v4-gguf/snapshots/86bb38ce2ba7a98ab0e550359fec5f48859dc723/DeepSeek-V4-Flash-Layers37-42Q4KExperts-OtherExpertLayersIQ2XXSGateUp-Q2KDown-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix-fixed-0731.gguf";
      port = 8050;
      ctxSize = 131072;
      tokens = 4096;
      threads = 32;
      prefillChunk = 1024;
      batchedSession = 3;
      kvDiskDir = "/scratch/ds4-kv";
      kvDiskSpaceMb = 65536;
      backend = "rocm";
    };
    security.harden.enable = true;
  };

  security.pam.loginLimits = [
    {
      domain = "son-of-anton";
      type = "hard";
      item = "memlock";
      value = "unlimited";
    }
  ];

  security.sudo-rs.extraRules = [
    {
      users = [ "son-of-anton" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/tee /proc/sys/vm/drop_caches";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

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
      "llama-cache"
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
