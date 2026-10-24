{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.webExtract;

  # nixpkgs' crawl4ai still depends on patchright, which is marked broken (its
  # metadata requirement is already removed), and on both litellm and
  # crawl4ai's own unclecode-litellm fork, whose files collide in one env.
  crawl4ai = pkgs.python3Packages.crawl4ai.overridePythonAttrs (old: {
    dependencies = builtins.filter (
      d:
      !(builtins.elem (d.pname or "") [
        "patchright"
        "litellm"
      ])
    ) old.dependencies;
  });
  python = pkgs.python3.withPackages (ps: [
    crawl4ai
    ps.aiohttp
    ps.charset-normalizer
    ps.httpx
    ps.pypdf
  ]);
  lanExposed = cfg.allowedClients != [ ];
in
{
  options.systemOptions.services.webExtract = {
    enable = lib.mkEnableOption "the Crawl4AI page-extraction service behind son-of-anton's web_extract";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8890;
    };
    allowedClients = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "LAN addresses that may call the service. Empty keeps it on loopback.";
    };
    resolvers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Internal DNS servers the service may reach; every other internal address is denied.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf lanExposed [ cfg.port ];

    systemd.services.web-extract = {
      description = "Crawl4AI page extraction";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      environment = {
        PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
        CRAWL4_AI_BASE_DIRECTORY = "/var/lib/web-extract";
        HOME = "/var/lib/web-extract";
      };

      serviceConfig = {
        ExecStart = lib.concatStringsSep " " [
          "${python}/bin/python3 -I ${./web_extract.py}"
          "--host ${if lanExposed then "0.0.0.0" else "127.0.0.1"}"
          "--port ${toString cfg.port}"
        ];
        DynamicUser = true;
        StateDirectory = "web-extract";
        Restart = "on-failure";
        RestartSec = 5;
        MemoryMax = "3G";

        # The browser follows redirects and loads subresources on its own, so the
        # unit, not the service's pre-fetch, keeps it off the LAN. Allow wins over
        # deny for the resolvers and the callers.
        IPAddressDeny = [
          "localhost"
          "link-local"
          "multicast"
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "100.64.0.0/10"
          "fc00::/7"
        ];
        IPAddressAllow = cfg.resolvers ++ cfg.allowedClients;

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
          "AF_NETLINK"
        ];
      };
    };
  };
}
