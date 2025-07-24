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
    host = "0.0.0.0";
    port = 8080;
  };
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."llm.ethanwtodd.com" = {
      globalRedirect = "llm.ethanwtodd.com:8080";
    };
  };
  services.searx = {
    enable = true;
    redisCreateLocally = true;
    settings = {
      server.port = 8888;
      server.bind_address = "0.0.0.0";
      server.secret_key = "test";
      search.formats = [ "html" "json" "rss" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 8888 ];
}
