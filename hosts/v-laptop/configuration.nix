{ ... }:
{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.intel.enable = true;
    # FIM completion (llama.vim in nvim) is supported but left off here: it
    # would mean compiling vulkan llama.cpp locally until v-devices can pull
    # builds from e-desktop. To enable, add a `qwen-fim` llamaSwap model (1.5B
    # for the Intel iGPU — see e-laptop's block for the shape); nixvim detects it.
    deviceType.laptop.enable = true;
    hardware.fingerprint.enable = true;
    hardware.frameworkLaptop.enable = true;
    services.suspend-then-hibernate.enable = true;
    services.tailscale.enable = true;
    services.binaryCache.consume = true;
    apps.zoom.enable = true;
    apps.remarkable.enable = true;
    apps.docker.enable = true;
  };

  users.users.v-play = {
    isNormalUser = true;
    description = "v-play";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "i2c"
      "docker"
    ];
  };
  users.users.v-work = {
    isNormalUser = true;
    description = "v-work";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "i2c"
      "docker"
    ];
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "v-laptop";
  system.stateVersion = "25.05";
}
