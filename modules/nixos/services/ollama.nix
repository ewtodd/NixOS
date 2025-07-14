{ pkgs, inputs, ... }:
let unstable = inputs.unstable.legacyPackages.${pkgs.system};
in {
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    package = unstable.ollama-rocm;
  };

  services.open-webui = {
    enable = true;
    host = "0.0.0.0"; # Allow access from any IP
    port = 8080;
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
