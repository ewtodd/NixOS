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
    };
    nix-colors.url = "github:misterio77/nix-colors";
    niri = {
      url = "github:YaLTeR/niri";
      inputs.rust-overlay.follows = "";
    };
    niri-nix = {
      url = "git+https://codeberg.org/BANanaD3V/niri-nix";
      inputs.git-hooks.follows = "";
      inputs.niri-unstable.follows = "niri";
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
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      unstable,
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
    };
}
