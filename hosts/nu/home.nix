{
  "nu" =
    { ... }:
    {
      home.username = "nu";
      home.homeDirectory = "/home/nu";
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
