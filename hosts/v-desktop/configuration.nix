{ ... }:
{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.amd.enable = true;
    # FIM completion (llama.vim in nvim) is supported but left off here: it
    # would mean compiling vulkan llama.cpp locally until v-devices can pull
    # builds from e-desktop. To enable, add a `qwen-fim` llamaSwap model (7B
    # for the 9060XT — see e-laptop's block for the shape); nixvim detects it.
    hardware.openRGB.enable = true;
    hardware.xbox.enable = true;
    deviceType.desktop.enable = true;
    services.ssh.enable = true;
    services.tailscale.enable = true;
    services.binaryCache.consume = true;
    owner.v.enable = true;
    services.suspend-then-hibernate.enable = true;
    apps.zoom.enable = true;
    apps.remarkable.enable = true;
    apps.quickemu.enable = true;
    apps.docker.enable = true;
  };

  nixpkgs.config.rocmTargets = [ "gfx1201" ];

  users.users.v-play = {
    isNormalUser = true;
    description = "v-play";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "i2c"
      "docker"
      "udev"
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
      "udev"
    ];
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "v-desktop";
  system.stateVersion = "25.05";
}
