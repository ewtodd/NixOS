{ config, lib, pkgs, ... }: {
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    settings = {
      wayland.enable = true;
    };
  };
}
