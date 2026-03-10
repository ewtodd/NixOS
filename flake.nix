{
  description = "Managing all the devices!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    base16 = {
      url = "github:SenchoPens/base16.nix";
    };
    niri = {
      url = "github:YaLTeR/niri?ref=wip/branch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-nix = {
      url = "git+https://codeberg.org/BANanaD3V/niri-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.git-hooks.follows = "";
      inputs.niri-unstable.follows = "";
      inputs.xwayland-satellite-unstable.follows = "";
    };
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dank-material-shell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.quickshell.follows = "quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
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
    banshee-ucm-conf = {
      url = "github:ewtodd/banshee-ucm-conf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      mkHomeManagerModules = inputs: [
        inputs.nixvim.homeModules.nixvim
        inputs.base16.homeManagerModule
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
          };
          modules = [
            ./modules
            inputs.home-manager.nixosModules.home-manager
            inputs.dank-material-shell.nixosModules.greeter
            inputs.banshee-ucm-conf.nixosModules.default
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

      mkNeovim = inputs.nixvim.legacyPackages.x86_64-linux.makeNixvimWithModule {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        module = {
          imports = [
            ./home-manager/packages/nixvim/opts.nix
            ./home-manager/packages/nixvim/keymaps.nix
            ./home-manager/packages/nixvim/plugins.nix
            ./home-manager/packages/nixvim/performance.nix
            ./home-manager/packages/nixvim/split.nix
          ];
          colorschemes.kanagawa = {
            enable = true;
          };
        };
      };

    in
    {
      lib = {
        inherit mkNeovim;
      };

      packages.x86_64-linux = {
        neovim = mkNeovim;
      };

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
