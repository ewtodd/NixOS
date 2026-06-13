{ ... }:
{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.intel.enable = true;
    services.llamaSwap = {
      enable = true;
      backend = "vulkan"; # Intel iGPU via ANV
      models."qwen-fim" = {
        hf = "ggml-org/Qwen2.5-Coder-1.5B-Q8_0-GGUF";
        ctxSize = 32768;
        ttl = 300;
        extraFlags = [
          "-ub 1024"
          "-b 1024"
          "-dt 0.1"
          "--cache-reuse 256"
        ];
      };
    };
    hardware.xbox.enable = true;
    hardware.chromebook-audio.enable = true;
    deviceType.laptop.enable = true;
    services.suspend-then-hibernate.enable = true;
    services.binaryCache.consume = true;
    security.harden.enable = true;
    owner.e.enable = true;
  };

  users.users.e-play = {
    isNormalUser = true;
    description = "ethan-play";
    extraGroups = [
      "input"
      "nixconfig"
      "networkmanager"
      "wheel"
      "dialout"
      "render"
      "video"
      "lp"
    ];
  };

  users.users.e-work = {
    isNormalUser = true;
    description = "ethan-work";
    extraGroups = [
      "input"
      "nixconfig"
      "networkmanager"
      "wheel"
      "dialout"
      "video"
      "lp"
    ];
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "e-laptop";
  system.stateVersion = "25.11";

}
