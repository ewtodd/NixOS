{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.systemOptions.services.adguard.enable {
    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      # Bind the web UI to all interfaces — binding to 10.0.0.1 races with
      # the LAN address assignment at boot. WAN exposure is blocked by the
      # firewall (LAN is the only trusted interface, and 3000 isn't in
      # allowedTCPPorts).
      host = "0.0.0.0";
      port = 3000;
      settings = {
        # DNS only listens on localhost on a non-53 port so it doesn't clash
        # with dnsmasq, which forwards queries here.
        dns = {
          bind_hosts = [ "127.0.0.1" ];
          port = 5353;
          upstream_dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          bootstrap_dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
        };
      };
    };
  };
}
