{ lib, ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/hardware/nvidia-graphics.nix
    ../../modules/nixos/hardware/openrgb.nix
    ../../modules/nixos/desktops/desktopEnvironment.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/quickemu.nix
    ../../modules/nixos/packages/zoom.nix
    ../../modules/nixos/packages/starship.nix
    ../../modules/nixos/services/ssh.nix
    ../../modules/nixos/services/tailscale.nix
  ];

  WindowManager = "sway";
  DeviceType = "desktop";
  environment.etc."sway-wrapper.sh".text = ''
    #!/bin/sh
    export WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:00:02.0-card
    exec sway "$@"
  '';
  environment.etc."sway-wrapper.sh".mode = "0755";
  environment.etc."xdg/wayland-sessions/sway.desktop".text = ''
    [Desktop Entry]
    Name=Sway (Intel Only)
    Comment=An i3-compatible Wayland compositor
    Exec=/etc/sway-wrapper.sh
    Type=Application
  '';

  users.users.v-play = {
    isNormalUser = true;
    description = "v-play";
    extraGroups = [ "networkmanager" "wheel" "i2c" ];
  };
  users.users.v-work = {
    isNormalUser = true;
    description = "v-work";
    extraGroups = [ "networkmanager" "wheel" "i2c" ];
  };
}
