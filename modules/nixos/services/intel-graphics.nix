{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    package = pkgs.mesa;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vpl-gpu-rt
      intel-media-driver
      vulkan-tools
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [ intel-vaapi-driver ];
  };
  environment.systemPackages = with pkgs; [ lm_sensors ];
}
