{ config, lib, pkgs, ... }: {
  config = lib.mkIf (config.WindowManager == "plasma") {

    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm = {
      enable = true;
      settings = { wayland.enable = true; };
    };
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
