{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    package = pkgs.mesa;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-tools
      rocmPackages.clr.icd
    ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
    lm_sensors
    nvtopPackages.amd
  ];

}
