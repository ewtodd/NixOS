{
  description = "Managing all the devices!";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nix-proton-cachyos.url = "github:ewtodd/nix-proton-cachyos";
    nix-colors.url = "github:misterio77/nix-colors";
    nixpkgs-cosmic-working = {
      url = "github:NixOS/nixpkgs/4206c4cb56751df534751b058295ea61357bbbaa";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, unstable, ... }: {
    nixosConfigurations = {
      v-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          system = "x86_64-linux";
        };
        modules = [
          {
            nixpkgs.overlays = [
              (final: prev:
                let
                  workingCosmicPkgs = import inputs.nixpkgs-cosmic-working {
                    system = prev.system;
                  };
                in {
                  cosmic-greeter = workingCosmicPkgs.cosmic-greeter;
                  cosmic-comp = workingCosmicPkgs.cosmic-comp;
                  cosmic-session = workingCosmicPkgs.cosmic-session;
                  cosmic-settings = workingCosmicPkgs.cosmic-settings;
                })
            ];
          }
          inputs.home-manager.nixosModules.home-manager
          inputs.chaotic.nixosModules.default
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              sharedModules = [
                inputs.nixvim.homeModules.nixvim
                inputs.nix-colors.homeManagerModules.default
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
          inputs.home-manager.nixosModules.home-manager
          inputs.chaotic.nixosModules.default
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              sharedModules = [
                inputs.nixvim.homeModules.nixvim
                inputs.nix-colors.homeManagerModules.default
              ];
              extraSpecialArgs = { inherit inputs; };
              users = import ./hosts/e-desktop/home.nix;
            };
          }
          ./hosts/e-desktop/configuration.nix
        ];
      };
      e-laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          system = "x86_64-linux";
        };
        modules = [
          inputs.home-manager.nixosModules.home-manager
          inputs.chaotic.nixosModules.default
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              sharedModules = [
                inputs.nixvim.homeModules.nixvim
                inputs.nix-colors.homeManagerModules.default
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
