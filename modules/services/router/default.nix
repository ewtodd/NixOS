{
  config,
  lib,
  ...
}:
let
  wan = "eno0";
  lan = "lan0";
  lanAddress = "10.0.0.7";
  lanPrefix = 24;
  adguardDnsPort = 5353;
in
{
  config = lib.mkIf config.systemOptions.services.router.enable {
    systemd.network.links."10-lan0" = {
      matchConfig.MACAddress = "9c:69:d3:3d:67:80";
      linkConfig.Name = "lan0";
    };

    networking.networkmanager.enable = lib.mkForce false;
    networking.useDHCP = lib.mkForce false;

    networking.interfaces.${wan} = {
      useDHCP = true;
      # Clone the BGW320's MAC so AT&T's DHCP hands over the lease without
      # the long re-auth delay that hits when the MAC changes.
      macAddress = "6c:4b:b4:53:3e:f0";
    };

    networking.interfaces.${lan} = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = lanAddress;
          prefixLength = lanPrefix;
        }
      ];
    };

    networking.nat = {
      enable = true;
      externalInterface = wan;
      internalInterfaces = [ lan ];
      # Public SSH for the bastion. Forward WAN:2222 to mu (10.0.0.2:2222),
      # which is where the bastion's hardened sshd lives.
      forwardPorts = [
        {
          sourcePort = 2222;
          proto = "tcp";
          destination = "10.0.0.2:2222";
        }
      ];
    };

    # Open the port on the WAN-facing firewall — the trustedInterfaces below
    # already accepts LAN traffic unconditionally.
    networking.firewall.allowedTCPPorts = [ 2222 ];

    networking.firewall.trustedInterfaces = [ lan ];

    services.dnsmasq = {
      enable = true;
      # The module default rewrites /etc/resolv.conf to 127.0.0.1; if dnsmasq
      # then fails to start, nu has no DNS for itself (tailscale, nix, etc.).
      # Let nu use whatever upstream WAN DHCP gives it.
      resolveLocalQueries = false;
      settings = {
        interface = lan;
        # bind-dynamic listens on interfaces as they come up; bind-interfaces
        # requires the address to be present at start and races with the
        # network-addresses-${lan}.service unit.
        bind-dynamic = true;
        # Don't read /etc/resolv.conf — forward everything to AdGuard, which
        # in turn forwards to the real upstreams.
        no-resolv = true;
        server = [ "127.0.0.1#${toString adguardDnsPort}" ];
        domain-needed = true;
        bogus-priv = true;
        cache-size = 0;

        dhcp-authoritative = true;
        dhcp-range = [ "10.0.0.100,10.0.0.250,24h" ];
        dhcp-option = [
          "option:router,${lanAddress}"
          "option:dns-server,${lanAddress}"
        ];
        dhcp-host = [
          "a6:d2:27:76:f4:c1,mu,10.0.0.2"
          "30:56:0f:4b:ac:de,desktop,10.0.0.4"
        ];
      };
    };
  };
}
