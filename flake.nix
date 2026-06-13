{
  description = "Managing all the devices!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
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
    niri-nix = {
      url = "git+https://codeberg.org/BANanaD3V/niri-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.niri-unstable.follows = "";
      inputs.xwayland-satellite-unstable.follows = "";
    };
    dank-material-shell = {
      url = "github:AvengeMedia/DankMaterialShell";
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
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
    };
    banshee-ucm-conf = {
      url = "github:ewtodd/banshee-ucm-conf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:zhaofengli/colmena";
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

      mkHeadlessHomeManagerModules = inputs: [
        inputs.nixvim.homeModules.nixvim
        inputs.base16.homeManagerModule
        {
          programs.nixvim.nixpkgs.useGlobalPackages = true;
        }
      ];

      # Shared per-host module list, consumed by both nixosConfigurations and
      # the colmena hive so the two can never drift. `headless` selects the
      # slimmer home-manager module set used by the DE-less server hosts.
      mkSystemModules =
        {
          hostname,
          headless,
        }:
        [
          ./modules
          inputs.home-manager.nixosModules.home-manager
          inputs.dank-material-shell.nixosModules.greeter
          inputs.banshee-ucm-conf.nixosModules.default
          {
            nixpkgs = {
              config.allowUnfree = true;
            };
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              sharedModules =
                if headless then mkHeadlessHomeManagerModules inputs else mkHomeManagerModules inputs;
              extraSpecialArgs = {
                inherit inputs;
                system = "x86_64-linux";
              };
              users = import ./hosts/${hostname}/home.nix;
            };
          }
          ./hosts/${hostname}/configuration.nix
        ];

      mkSystem =
        {
          hostname,
          headless ? false,
        }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            system = "x86_64-linux";
          };
          modules = mkSystemModules { inherit hostname headless; };
        };

      # Every host, and whether it's a headless (server) build.
      hosts = {
        v-desktop = {
          headless = false;
        };
        v-laptop = {
          headless = false;
        };
        e-desktop = {
          headless = false;
        };
        e-laptop = {
          headless = false;
        };
        server-nu = {
          headless = true;
        };
        server-mu = {
          headless = true;
        };
        anton = {
          headless = true;
        };
        son-of-anton = {
          headless = true;
        };
      };

      # Colmena-managed subset (v-devices are intentionally excluded for now).
      # Workstations deploy locally; the headless servers are pushed from the
      # build host (e-desktop) over SSH as the `deploy` user. The targetHost
      # values are `*-deploy` ssh aliases (defined in the e-owner ssh config)
      # that jump through the bastion, so deploys work on- and off-LAN.
      colmenaDeployments = {
        e-desktop = {
          allowLocalDeployment = true;
          targetHost = null;
          tags = [ "workstation" ];
        };
        e-laptop = {
          allowLocalDeployment = true;
          targetHost = null;
          tags = [ "workstation" ];
        };
        server-nu = {
          targetHost = "nu-deploy";
          targetUser = "deploy";
          buildOnTarget = false;
          tags = [ "server" ];
        };
        server-mu = {
          targetHost = "mu-deploy";
          targetUser = "deploy";
          buildOnTarget = false;
          tags = [
            "server"
            "bastion"
          ];
        };
        anton = {
          targetHost = "anton-deploy";
          targetUser = "deploy";
          buildOnTarget = false;
          tags = [ "server" ];
        };
        son-of-anton = {
          targetHost = "son-of-anton-deploy";
          targetUser = "deploy";
          buildOnTarget = false;
          tags = [ "server" ];
        };
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

      nixosConfigurations = builtins.mapAttrs (
        hostname: h:
        mkSystem {
          inherit hostname;
          inherit (h) headless;
        }
      ) hosts;

      # Raw colmena hive. Each node reuses the exact same modules as its
      # nixosConfiguration plus a `deployment` block. meta.nixpkgs supplies
      # allowUnfree as a low-priority default; colmena evaluates nodes through
      # nixos/lib/eval-config.nix, so per-host nixpkgs.config (e.g. rocmTargets
      # on son-of-anton) still merges normally.
      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          specialArgs = {
            inherit inputs;
            system = "x86_64-linux";
          };
        };
      }
      // builtins.mapAttrs (hostname: deployment: {
        imports = mkSystemModules {
          inherit hostname;
          inherit (hosts.${hostname}) headless;
        };
        inherit deployment;
      }) colmenaDeployments;

      # New-evaluator entrypoint the colmena CLI prefers.
      colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
    };
}
