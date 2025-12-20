{ ... }: {
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      AuthenticationMethods = "password";
      AllowUsers = [ "e-work" "e-play" "v-work" "v-play" ];
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 2222 ];
  };
}
