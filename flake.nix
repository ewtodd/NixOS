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
    llama-cpp = {
      url = "github:ggml-org/llama.cpp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    arxiv-mcp-server-src = {
      url = "github:blazickjp/arxiv-mcp-server";
      flake = false;
    };
    split-nvim-src = {
      url = "github:wurli/split.nvim";
      flake = false;
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
        inputs.dms-plugin-registry.homeModules.default
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
          targetHost = "deploy-nu";
          targetUser = "deploy";
          buildOnTarget = false;
          tags = [ "server" ];
        };
        server-mu = {
          targetHost = "deploy-mu";
          targetUser = "deploy";
          buildOnTarget = false;
          tags = [
            "server"
            "bastion"
          ];
        };
        anton = {
          targetHost = "deploy-anton";
          targetUser = "deploy";
          buildOnTarget = false;
          tags = [ "server" ];
        };
        son-of-anton = {
          targetHost = "deploy-son-of-anton";
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
            (import ./home-manager/packages/nixvim/split.nix inputs)
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

      colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
    };
}
