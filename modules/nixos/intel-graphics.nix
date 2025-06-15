{ pkgs, unstable, ... }: {
  hardware.graphics = {
    enable = true;
    package = unstable.mesa;
    enable32Bit = true;
    extraPackages = with unstable; [
      vpl-gpu-rt
      libvdpau-va-gl
      intel-media-driver
      intel-compute-runtime
      vulkan-tools
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [ intel-vaapi-driver ];
  };
  environment.systemPackages = with pkgs; [ lm_sensors nvtopPackages.intel ];
  hardware.intel-gpu-tools.enable = true;
}
