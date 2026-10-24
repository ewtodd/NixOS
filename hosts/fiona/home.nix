{
  "fiona" =
    { ... }:
    {
      home.username = "fiona";
      home.homeDirectory = "/home/fiona";
      home.stateVersion = "26.11";
      imports = [
        ../../home-manager/profiles/server.nix
      ];
    };
  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "26.11";
      imports = [
        ../../home-manager/profiles/server.nix
      ];
    };
}
