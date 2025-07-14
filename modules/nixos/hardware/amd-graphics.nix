{ pkgs, inputs, ... }:
let unstable = inputs.unstable.legacyPackages.${pkgs.system};
in {
  hardware.graphics = {
    enable = true;
    package = unstable.mesa;
    enable32Bit = true;
    extraPackages = with unstable; [ vulkan-tools rocmPackages.clr.icd ];

  };
  # Allow unfree packages (required for ROCm)
  nixpkgs.config.allowUnfree = true;

  # Configure ROCm targets for RX 7900 XTX
  nixpkgs.config.rocmTargets = [ "gfx1100" ];

  # Add ROCm packages to system packages
  environment.systemPackages = with pkgs; [
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
    lm_sensors
    nvtopPackages.amd
  ];

}
