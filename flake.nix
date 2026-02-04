{
  description = "Managing all the devices!";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    niri-nix = {
      url = "git+https://codeberg.org/BANanaD3V/niri-nix";
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
    SRIM.url = "github:ewtodd/SRIM-nix";
    lisepp.url = "github:ewtodd/LISEplusplus-nix";
    remarkable.url = "github:ewtodd/reMarkable-nix";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-borders = {
      url = "github:FelixKratz/homebrew-formulae";
      flake = false;
    };
    homebrew-jxz = {
      url = "github:J-x-Z/homebrew-tap";
      flake = false;
    };
      };

  outputs =
    inputs@{
      self,
      nixpkgs,
      unstable,
      nix-darwin,
      ...
    }:
    {
      nixosConfigurations = {
        v-desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            system = "x86_64-linux";
          };
          modules = [
            ./modules
            inputs.home-manager.nixosModules.home-manager
            inputs.dank-material-shell.nixosModules.greeter
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                sharedModules = [
                  inputs.nixvim.homeModules.nixvim
                  inputs.nix-colors.homeManagerModules.default
                  inputs.dank-material-shell.homeModules.dank-material-shell
                  inputs.danksearch.homeModules.dsearch
                  inputs.dms-plugin-registry.modules.default
                  inputs.niri-nix.homeModules.default
                ];
                extraSpecialArgs = { inherit inputs; };
                users = import ./hosts/v-desktop/home.nix;
              };
            }
            ./hosts/v-desktop/configuration.nix
          ];
        };
        e-desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            system = "x86_64-linux";
            unstable = import unstable { system = "x86_64-linux"; };
          };
          modules = [
            ./modules
            inputs.lanzaboote.nixosModules.lanzaboote
            inputs.home-manager.nixosModules.home-manager
            inputs.dank-material-shell.nixosModules.greeter
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                sharedModules = [
                  inputs.nixvim.homeModules.nixvim
                  inputs.nix-colors.homeManagerModules.default
                  inputs.dank-material-shell.homeModules.dank-material-shell
                  inputs.danksearch.homeModules.dsearch
                  inputs.dms-plugin-registry.modules.default
                  inputs.niri-nix.homeModules.default
                ];
                extraSpecialArgs = { inherit inputs; };
                users = import ./hosts/e-desktop/home.nix;
              };
            }
            ./hosts/e-desktop/configuration.nix
          ];
        };
        v-laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            system = "x86_64-linux";
          };
          modules = [
            ./modules
            inputs.home-manager.nixosModules.home-manager
            inputs.dank-material-shell.nixosModules.greeter
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                sharedModules = [
                  inputs.nixvim.homeModules.nixvim
                  inputs.nix-colors.homeManagerModules.default
                  inputs.dank-material-shell.homeModules.dank-material-shell
                  inputs.danksearch.homeModules.dsearch
                  inputs.dms-plugin-registry.modules.default
                  inputs.niri-nix.homeModules.default
                ];
                extraSpecialArgs = { inherit inputs; };
                users = import ./hosts/v-laptop/home.nix;
              };
            }
            ./hosts/v-laptop/configuration.nix
          ];
        };
        e-laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            system = "x86_64-linux";
          };
          modules = [
            ./modules
            inputs.home-manager.nixosModules.home-manager
            inputs.dank-material-shell.nixosModules.greeter
            inputs.lanzaboote.nixosModules.lanzaboote
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                sharedModules = [
                  inputs.nixvim.homeModules.nixvim
                  inputs.nix-colors.homeManagerModules.default
                  inputs.dank-material-shell.homeModules.dank-material-shell
                  inputs.danksearch.homeModules.dsearch
                  inputs.dms-plugin-registry.modules.default
                  inputs.niri-nix.homeModules.default
                ];
                extraSpecialArgs = { inherit inputs; };
                users = import ./hosts/e-laptop/home.nix;
              };
            }
            ./hosts/e-laptop/configuration.nix
          ];
        };
      };
      darwinConfigurations."e-darwin" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              sharedModules = [
                inputs.nixvim.homeModules.nixvim
                inputs.nix-colors.homeManagerModules.default
              ];
              extraSpecialArgs = { inherit inputs; };
              users = import ./hosts/e-darwin/home.nix;
            };
          }
          inputs.nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "e-host";
              taps = {
                "homebrew/homebrew-core" = inputs.homebrew-core;
                "homebrew/homebrew-cask" = inputs.homebrew-cask;
                "FelixKratz/homebrew-formulae" = inputs.homebrew-borders;
                "J-x-Z/homebrew-tap" = inputs.homebrew-jxz;
              };
              mutableTaps = false;
            };
          }
          ./hosts/e-darwin/configuration.nix
        ];
      };
    };
}
