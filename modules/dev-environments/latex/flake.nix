{
  description = "LaTeX development environment with elsarticle";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux"; # Change to your system
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          (pkgs.texliveFull.withPackages
            (ps: with ps; [ elsarticle collection-publishers ]))
        ];

        shellHook = ''
          # Force TeX to rebuild its file database
          mktexlsr
          echo "TeX Live database updated"

          # Test if elsarticle.cls can be found
          if kpsewhich elsarticle.cls; then
            echo "✓ elsarticle.cls found"
          else
            echo "✗ elsarticle.cls still not found"
          fi
        '';
      };
    };
}
