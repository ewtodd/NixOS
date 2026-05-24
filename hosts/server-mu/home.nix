{
  "mu" =
    { ... }:
    {
      home.username = "mu";
      home.homeDirectory = "/home/mu";
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
