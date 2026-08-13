{
  "son-of-anton" =
    { ... }:
    {
      home.username = "son-of-anton";
      home.homeDirectory = "/home/son-of-anton";
      home.stateVersion = "25.11";
      imports = [
        ../../home-manager/profiles/server.nix
      ];
    };
  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "25.11";
      imports = [
        ../../home-manager/profiles/server.nix
      ];
    };
}
