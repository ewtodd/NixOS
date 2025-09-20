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
    nix-colors.url = "github:misterio77/nix-colors";
    nix-mineral = {
      url = "github:cynicsketch/nix-mineral";
      flake = false;
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
          inputs.home-manager.nixosModules.home-manager
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
              users = import ./hosts/e-laptop/home.nix;
            };
          }
          ./hosts/e-laptop/configuration.nix
        ];
      };
      v-framework = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          system = "x86_64-linux";
        };
        modules = [
          inputs.nixos-hardware.nixosModules.framework-11th-gen-intel
          inputs.home-manager.nixosModules.home-manager
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
              users = import ./hosts/v-framework/home.nix;
            };
          }
          ./hosts/v-framework/configuration.nix
        ];
      };
      e-framework = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          system = "x86_64-linux";
        };
        modules = [
          inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
          inputs.home-manager.nixosModules.home-manager
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
              users = import ./hosts/e-framework/home.nix;
            };
          }
          ./hosts/e-framework/configuration.nix
        ];
      };
    };
  };
}
