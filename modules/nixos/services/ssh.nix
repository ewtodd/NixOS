{ ... }: {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      AuthenticationMethods = "publickey,password";
      PermitRootLogin = "prohibit-password";
      AllowUsers = [ "e-work" "e-play" "v-work" "v-play" ];
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };
}
