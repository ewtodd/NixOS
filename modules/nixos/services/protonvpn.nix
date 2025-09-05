{ ... }:
let server-ip = "193.148.18.82";
in {
  networking.firewall = { allowedUDPPorts = [ 51820 ]; };
  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "10.2.0.2/32" ];
      dns = [ "10.2.0.1" ];
      privateKeyFile = "/etc/wireguard-proton.key";

      peers = [{
        publicKey = "R8Of+lrl8DgOQmO6kcjlX7SchP4ncvbY90MB7ZUNmD8=";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        endpoint = "${server-ip}:51820";
        persistentKeepalive = 25;
      }];
    };
  };
}
