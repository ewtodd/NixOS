{ pkgs, inputs, ... }:
let unstable = inputs.unstable.legacyPackages.${pkgs.system};
in {
  hardware.graphics = {
    enable = true;
    package = unstable.mesa;
    enable32Bit = true;
    extraPackages = with unstable; [ vulkan-tools ];

  };
  environment.systemPackages = with pkgs; [ lm_sensors nvtopPackages.amd ];
}
