{
  "e-host" =
    { inputs, ... }:
    {
      home.username = "e-host";
      home.stateVersion = "25.11";

      imports = [
        ../../home-manager/common/profiles/work.nix
      ];

      colorScheme = inputs.nix-colors.colorSchemes.harmonic16-dark;
    };
}
