{ config, pkgs, inputs, ... }:
let unstable = inputs.unstable.legacyPackages.${pkgs.system};
in {

  nixpkgs.config.allowUnfree = true;
  hardware.graphics = {
    enable = true;
    package = unstable.mesa;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = true;
    open = true;
  };
  environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];
}
