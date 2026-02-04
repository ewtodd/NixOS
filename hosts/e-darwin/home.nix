{
  "e-darwin" =
    { ... }:
    {
      home.username = "e-darwin";
      home.stateVersion = "25.11";

      imports = [
        ../../home-manager/common/profiles/root.nix
      ];

    };
}
