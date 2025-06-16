{ config, pkgs, inputs, ... }:
let
  unstable = import inputs.unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in {
  nixpkgs.config.allowUnfree = true;
  hardware.graphics = {
    enable = true;
    package = unstable.mesa;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    package = pkgs.linuxPackages.nvidiaPackages.production;
    nvidiaSettings = true;
    open = true;
  };
  environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];
}
