{
  "anton" =
    { ... }:
    {
      home.username = "anton";
      home.homeDirectory = "/home/anton";
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
