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
      url = "github:AvengeMedia/DankMaterialShell/stable";
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
    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    temple = {
      url = "github:ewtodd/temple";
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
          system ? "x86_64-linux",
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
                system = system;
              };
              users = import ./hosts/${hostname}/home.nix;
            };
            # Make the per-host system string available to all NixOS modules
            # as `system` (overrides any meta.specialArgs from colmena so each
            # node gets its own arch, not the build host's).
            _module.args.system = system;
          }
          ./hosts/${hostname}/configuration.nix
        ]
        ++ nixpkgs.lib.optional (
          hostname == "oracle"
        ) inputs.nixos-apple-silicon.nixosModules.apple-silicon-support;

      mkSystem =
        {
          hostname,
          headless ? false,
          system ? "x86_64-linux",
        }:
        nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = {
            inherit inputs;
            system = system;
          };
          modules = mkSystemModules {
            inherit hostname headless system;
          };
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
        oracle = {
          headless = true;
          system = "aarch64-linux";
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
        oracle = {
          targetHost = "deploy-oracle";
          targetUser = "deploy";
          buildOnTarget = true;
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
          system = h.system or "x86_64-linux";
        }
      ) hosts;

      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          nodeNixpkgs = {
            oracle = import nixpkgs {
              system = "aarch64-linux";
              config.allowUnfree = true;
            };
          };
          specialArgs = {
            inherit inputs;
          };
        };
      }
      // builtins.mapAttrs (hostname: deployment: {
        imports = mkSystemModules {
          inherit hostname;
          inherit (hosts.${hostname}) headless;
          system = hosts.${hostname}.system or "x86_64-linux";
        };
        inherit deployment;
      }) colmenaDeployments;

      colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
    };
}
