{ config, pkgs, ... }: {
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  environment.systemPackages = [ pkgs.distrobox ];
  environment.shellAliases = { debian = "distrobox enter debian"; };
}
