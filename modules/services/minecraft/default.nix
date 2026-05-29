{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

  config = lib.mkIf config.systemOptions.services.minecraft.enable {
    nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

    services.minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = true;

      servers.main = {
        enable = true;
        package = pkgs.paperServers.paper;
        jvmOpts = "-Xms2G -Xmx4G";

        serverProperties = {
          server-port = 25565;
          motd = "ethanwtodd.com";
          max-players = 10;
          online-mode = true;
          white-list = true;
          enforce-whitelist = true;
          difficulty = "normal";
          view-distance = 10;
        };
      };
    };
  };
}
