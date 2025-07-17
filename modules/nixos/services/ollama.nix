{ pkgs, inputs, ... }:
let unstable = inputs.unstable.legacyPackages.${pkgs.system};
in {
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    package = unstable.ollama-rocm;
  };

  
}
