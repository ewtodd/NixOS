{ config, ... }:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
  ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    deviceType.server.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.binaryCache.consume = true;
    services.bastion.enable = true;
    # e-desktop powers off Sun and Wed at 05:00 (plus up to 2 minutes of
    # jitter); leave the shutdown room to finish, then wake it back up.
    services.bastion.wakeCalendar = "Sun,Wed *-*-* 05:10:00";
    services.nextcloud.enable = true;
    services.minecraft.enable = true;
    services.nodeExporter.enable = true;
    services.scheduledReboot.enable = true;
    services.scheduledReboot.calendar = "*-*-* 04:30:00";
    # Signal bot backend for the son-of-anton gateway on e-desktop (HTTP
    # JSON-RPC mode — the interface the gateway's Signal adapter speaks).
    # Runs on x86_64; the gateway reaches it over the LAN.
    services.signal-cli = {
      enable = true;
      environmentFile = config.age.secrets.signal-cli-env.path;
      socketAddr = "0.0.0.0:7583";
      openFirewall = true;
    };

    # The AI front, moved here from oracle (systemOptions.aiFrontAddress points the clients and nu's
    # reverse proxy at this host): maitred (/v1 and /mcp on :4002),
    # Open WebUI and SearXNG. Title generation and embeddings are on fiona.
    services.maitred = {
      enable = true;
      environmentFiles = [
        config.age.secrets.maitred-env.path
        config.age.secrets.maitred-keys.path
      ];
    };
    services.searxng = {
      enable = true;
      listenAddress = "0.0.0.0";
      openFirewall = true;
    };
    services.openWebUI.enable = true;
    security.harden.enable = true;
  };

  users.users.mu = {
    isNormalUser = true;
    description = "mu";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "mu";
  system.stateVersion = "25.11";
}
