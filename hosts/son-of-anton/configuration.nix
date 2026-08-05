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
    services.llamaSwap = {
      enable = true;
      lanExpose = true;
      backend = "rocm";
      cacheDir = "/scratch/llama-cache";
      models = {
        "deepseek-v4-flash" = {
          hf = "unsloth/DeepSeek-V4-Flash-0731-GGUF:UD-IQ3_XXS";
          ctxSize = 524288;
          alwaysResident = true;
          mlock = true;
          batchSize = 2048;
          ubatchSize = 1024;
          kQuant = "bf16";
          vQuant = "bf16";
          parallel = 1;
          flashAttn = "on";
          specType = "draft-dspark";
          specDraftNMax = 3;
          specDraftModel = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/DeepSeek-V4-Flash-0731-GGUF/resolve/main/dspark-DeepSeek-V4-Flash-0731-Q8_0.gguf";
            hash = "sha256-LHrFSwtkqZ3x8Tmp8TcaABmCZeHWphS3dZfSCmVaQkk=";
          };
          extraFlags = [
            "--temp 1.0"
            "--top-p 0.95"
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
