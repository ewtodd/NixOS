{ ... }:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINoytDv0UZeMmWFoYaGQkLpTdOmo7iefXmZmgxM4FxVb soa-ricky@e-desktop"
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
    services.unholy = {
      enable = true;
      lanExpose = true;
      model = "/scratch/dsv4-ve";
      kvTokens = 1572864;
      maxModelLen = 786432;
      maxNumSeqs = 8;
      specDrafts = 5;
      prefixSnapshots = 64;
      managers = [ "son-of-anton" ];
    };
    services.radiance = {
      enable = true;
      lanExpose = true;
      model = "/scratch/models/rad/swift15-27b-fp8-df2.rad";
      servedModelName = "qwen3.8-27b";
      maxModelLen = 352256;
      ropeScaling = "yarn:1.34375";
      maxNumSeqs = 8;
      kvCacheDtype = "bf16";
      prefixCacheMib = 0;
      checkpointSlots = 8;
    };
    services.gufoStrix = {
      enable = true;
      lanExpose = true;
      model = "/scratch/models/gufo/qwen3.8-flash-next/Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf";
      mtpModel = "/scratch/models/gufo/qwen3.8-flash-next/mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf";
      draftTokens = 5;
      mmproj = "/scratch/models/gufo/qwen3.8-flash-next/mmproj-BF16.gguf";
      sessions = 2;
      context = 262144;
      yarn = false;
      diskCacheDir = "/scratch/gufo-cache";
      diskCacheBytes = 64 * 1024 * 1024 * 1024;
      logProgress = true;
    };
    services.llmMode = {
      enable = true;
      default = "ds4";
      managers = [ "son-of-anton" ];
    };
    security.harden.enable = true;
  };

  nixpkgs.config.rocmTargets = [
    "gfx1151"
    "gfx1201"
  ];
  users.groups.llama-cache = { };

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
