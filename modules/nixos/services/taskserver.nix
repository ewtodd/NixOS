{ config, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 53589 ];

  services.taskserver = {
    enable = true;
    fqdn = "taskserver.ethanwtodd.com";  # Replace with your actual domain
    listenHost = "0.0.0.0";  # Listen on all interfaces for external access
    organisations.personal.users = [ "e-work" "e-play" ];  # Replace with your username
  };

  environment.systemPackages = with pkgs; [
    openssl  # For certificate fingerprint verification
  ];
}
