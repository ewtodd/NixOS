{
  description = "Managing all the devices!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
    };
    niri = {
      url = "github:YaLTeR/niri?ref=wip/branch";
      inputs.nixpkgs.follows = "unstable";
    };
    niri-nix = {
      url = "git+https://codeberg.org/BANanaD3V/niri-nix";
      inputs.nixpkgs.follows = "unstable";
      inputs.git-hooks.follows = "";
      inputs.niri-unstable.follows = "";
      inputs.xwayland-satellite-unstable.follows = "";
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "unstable";
    };
    dank-material-shell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "unstable";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "unstable";
    };
    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "unstable";
    };
    SRIM = {
      url = "github:ewtodd/SRIM-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lisepp = {
      url = "github:ewtodd/LISEplusplus-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    remarkable = {
      url = "github:ewtodd/reMarkable-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      unstable,
      ...
    }:
    let
      mkHomeManagerModules = inputs: [
        inputs.nixvim.homeModules.nixvim
        inputs.nix-colors.homeManagerModules.default
        inputs.dank-material-shell.homeModules.dank-material-shell
        inputs.danksearch.homeModules.dsearch
        inputs.dms-plugin-registry.modules.default
        inputs.niri-nix.homeModules.default
        {
          programs.nixvim.nixpkgs.useGlobalPackages = true;
        }
      ];

      mkNixSystem =
        {
          hostname,
          useLanzaboote ? false,
        }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            system = "x86_64-linux";
            unstable = import unstable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
          modules = [
            ./modules
            inputs.home-manager.nixosModules.home-manager
            inputs.dank-material-shell.nixosModules.greeter
            {
              nixpkgs.config.allowUnfree = true;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                sharedModules = mkHomeManagerModules inputs;
                extraSpecialArgs = {
                  inherit inputs;
                  system = "x86_64-linux";
                  unstable = import unstable {
                    system = "x86_64-linux";
                    config.allowUnfree = true;
                  };
                };
                users = import ./hosts/${hostname}/home.nix;
              };
            }
            ./hosts/${hostname}/configuration.nix
          ]
          ++ nixpkgs.lib.optionals useLanzaboote [
            inputs.lanzaboote.nixosModules.lanzaboote
          ];
        };

    in
    {
      nixosConfigurations = {
        v-desktop = mkNixSystem { hostname = "v-desktop"; };
        v-laptop = mkNixSystem { hostname = "v-laptop"; };
        e-desktop = mkNixSystem {
          hostname = "e-desktop";
          useLanzaboote = true;
        };
        e-laptop = mkNixSystem {
          hostname = "e-laptop";
          useLanzaboote = true;
        };
      };
    };
}
