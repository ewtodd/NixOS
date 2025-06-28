{ config, lib, pkgs, ... }: {
  config = lib.mkIf (config.WindowManager == "cosmic") {
    services.desktopManager.cosmic = {
      enable = true;
      xwayland.enable = true;
    };
    services.displayManager.cosmic-greeter.enable = true;
    environment.systemPackages = with pkgs; [ wl-clipboard ];
  };
}
