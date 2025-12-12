{ ... }:
let server-ip = "146.70.84.2";
in {
  networking.firewall = { allowedUDPPorts = [ 51820 ]; };
  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "10.2.0.2/32" ];
      dns = [ "10.2.0.1" ];
      privateKeyFile = "/etc/wireguard-proton.key";

      peers = [{
        publicKey = "Rtsl6k9WA9t04Vt+EDUD3TlSr9+YL6YcTFwiSB1qBwA=";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        endpoint = "${server-ip}:51820";
        persistentKeepalive = 25;
      }];
    };
  };
}
