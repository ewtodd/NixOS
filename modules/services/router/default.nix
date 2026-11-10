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
  # Wi-Fi: the AP (OpenWrt) tags every SSID's traffic with VLAN 20 on its
  # uplink, so Wi-Fi clients reach nu only through this interface.
  wifi = "${lan}.20";
  wifiAddress = "10.0.20.1";
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

    networking.vlans.${wifi} = {
      id = 20;
      interface = lan;
    };

    networking.interfaces.${wifi} = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = wifiAddress;
          prefixLength = 24;
        }
      ];
    };

    networking.nat = {
      enable = true;
      externalInterface = wan;
      internalInterfaces = [
        lan
        wifi
      ];
      forwardPorts = [
        {
          sourcePort = 2222;
          proto = "tcp";
          destination = "10.0.0.2:2222";
        }
        {
          sourcePort = 25565;
          proto = "tcp";
          destination = "10.0.0.2:25565";
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [ 2222 ];

    # Global openings (22, 80, 443, 2222) cover the rest; UDP 443 keeps HTTP/3
    # working for LAN clients, which the WAN side has never been offered.
    networking.firewall.interfaces = lib.genAttrs [ lan wifi ] (_: {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [
        53
        67
        443
      ];
    });

    # The iptables firewall filters only what is addressed to nu; forwarded
    # traffic passes by default, so nu would route Wi-Fi straight onto the LAN.
    # Wi-Fi may answer connections the LAN opened and reach the Internet, and
    # nothing private. The jump is deleted before it is inserted so a firewall
    # reload does not stack copies.
    networking.firewall.extraCommands = ''
      iptables -w -N nixos-wifi-fwd 2>/dev/null || iptables -w -F nixos-wifi-fwd
      iptables -w -A nixos-wifi-fwd -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
      iptables -w -A nixos-wifi-fwd -d 10.0.0.0/8 -j DROP
      iptables -w -A nixos-wifi-fwd -d 172.16.0.0/12 -j DROP
      iptables -w -A nixos-wifi-fwd -d 192.168.0.0/16 -j DROP
      iptables -w -A nixos-wifi-fwd -d 100.64.0.0/10 -j DROP
      iptables -w -D FORWARD -i ${wifi} -j nixos-wifi-fwd 2>/dev/null || true
      iptables -w -I FORWARD -i ${wifi} -j nixos-wifi-fwd
    '';
    networking.firewall.extraStopCommands = ''
      iptables -w -D FORWARD -i ${wifi} -j nixos-wifi-fwd 2>/dev/null || true
      iptables -w -F nixos-wifi-fwd 2>/dev/null || true
      iptables -w -X nixos-wifi-fwd 2>/dev/null || true
    '';

    services.dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      settings = {
        interface = [
          lan
          wifi
        ];
        bind-dynamic = true;
        no-resolv = true;
        server = [ "127.0.0.1#${toString adguardDnsPort}" ];
        domain-needed = true;
        bogus-priv = true;
        cache-size = 0;

        address = [
          "/mc.ethanwtodd.com/10.0.0.2"
          "/ssh.ethanwtodd.com/10.0.0.2"
        ];

        dhcp-authoritative = true;
        # No router or DNS options: dnsmasq gives each client its own address
        # on the interface the request came in on (10.0.0.7 or 10.0.20.1) for
        # both, which a single explicit option could not.
        dhcp-range = [
          "10.0.0.100,10.0.0.250,24h"
          "10.0.20.100,10.0.20.250,12h"
        ];
        dhcp-host = [
          "a6:d2:27:76:f4:c1,mu,10.0.0.2"
          "30:56:0f:4b:ac:de,e-workstation,10.0.0.4"
          "d8:bb:c1:d8:7d:49,anton,10.0.0.3"
          "9c:bf:0d:01:ec:71,son-of-anton,10.0.0.5"
          "b0:25:aa:51:54:b0,fiona,10.0.0.6"
          # enp4s0, the NIC with carrier. The board has two; enp3s0
          # (a8:b8:e0:0a:94:5c) is unused.
          "a8:b8:e0:0a:94:5d,tony,10.0.0.8"
        ];
      };
    };
  };
}
