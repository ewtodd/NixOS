{
  description = "Managing all the devices!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-oracle.url = "github:NixOS/nixpkgs/c59305bab2065cfecc4944690d9eedbb56f3a9fa";
    wireview-linux = {
      url = "github:ewtodd/wireview-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bifrost = {
      url = "github:maximhq/bifrost";
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
    website = {
      url = "github:ewtodd/website";
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
    };
    gufo = {
      url = "github:gufo-org/gufo";
    };
    vllm-radiance-src = {
      url = "github:ewtodd/vllm-radiance-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
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
      inputs.nixpkgs.follows = "nixpkgs-oracle";
    };
    son-of-anton = {
      url = "github:ewtodd/son-of-anton";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-utilities = {
      url = "github:ewtodd/niri-utilities";
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

      # Fixes for the aarch64/open-webui closure. These live here, not in the
      # open-webui module, because colmena's nodeNixpkgs replaces the node's
      # package set and silently ignores module-level nixpkgs.overlays.
      openWebUIOverlays = [
        (_: prev: {
          python314 = prev.python314.override {
            packageOverrides = _: pythonPkgs: {
              # pypdf's zlib recovery-path speed test asserts a hard 10 s budget
              # and times out on the aarch64 builder; skip the suite.
              pypdf = pythonPkgs.pypdf.overridePythonAttrs (_: {
                doCheck = false;
              });
              # Its checks pull every optional dependency, including
              # transformers' audio extra -> torchaudio, into the closure.
              # None of that is needed to install or run it.
              sentence-transformers = pythonPkgs.sentence-transformers.overridePythonAttrs (_: {
                nativeCheckInputs = [ ];
                doCheck = false;
              });
              # These two are runtime deps of open-webui, but their check
              # inputs are the last things dragging torch/transformers in.
              einops = pythonPkgs.einops.overridePythonAttrs (_: {
                nativeCheckInputs = [ ];
                doCheck = false;
              });
              ctranslate2 = pythonPkgs.ctranslate2.overridePythonAttrs (_: {
                nativeCheckInputs = [ ];
                doCheck = false;
              });
            };
          };
        })
        # Second overlay so prev.open-webui is rebuilt against the python314
        # above; overriding both in one overlay leaves it on the base python set.
        (_: prev: {
          # Local embedding/reranking, TTS and evaluation backends. This
          # deployment sends chat to Bifrost and embeddings to the llama.cpp
          # bge-m3 server, so transformers/sentence-transformers/colbert-ai
          # and their accelerate->torch stack are dead weight; all their
          # imports are lazy.
          open-webui = prev.open-webui.overridePythonAttrs (old: {
            dependencies = builtins.filter (
              dep:
              !(builtins.elem (dep.pname or "") [
                "accelerate"
                "sentence-transformers"
                "transformers"
                "colbert-ai"
              ])
            ) old.dependencies;
            # The wheel still advertises those extras in Requires-Dist; strip
            # them so the runtime deps check sees metadata matching the env.
            pythonRemoveDeps = [
              "accelerate"
              "colbert-ai"
              "sentence-transformers"
              "transformers"
            ];
          });
        })
      ];

      mkSystemModules =
        {
          hostname,
          headless,
          system ? "x86_64-linux",
        }:
        [
          ./modules
          { nixpkgs.overlays = openWebUIOverlays; }
          inputs.home-manager.nixosModules.home-manager
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
        let
          hostNixpkgs = if hostname == "oracle" then inputs.nixpkgs-oracle else nixpkgs;
        in
        hostNixpkgs.lib.nixosSystem {
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
        nu = {
          headless = true;
        };
        mu = {
          headless = true;
        };
        anton = {
          headless = true;
        };
        tony = {
          headless = false;
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
        nu = {
          targetHost = "deploy-nu";
          targetUser = "deploy";
          buildOnTarget = false;
          tags = [ "server" ];
        };
        mu = {
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
        tony = {
          targetHost = "deploy-tony";
          targetUser = "deploy";
          buildOnTarget = false;
          tags = [ "appliance" ];
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

      packages.x86_64-linux =
        let
          vllmStack = inputs.vllm-radiance-src.lib.x86_64-linux.mkVllmStack {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
        in
        {
          neovim = mkNeovim;
          vllm-torch = vllmStack.torch;
          vllm-aiter = vllmStack.aiter;
          vllm-libr4d = vllmStack.libr4d;
          vllm-engine = vllmStack.vllm;
          vllm-env = vllmStack.pythonEnv;
          rocm-sdk-gfx120X = vllmStack.rocmSdk;
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
            oracle = import inputs.nixpkgs-oracle {
              system = "aarch64-linux";
              config.allowUnfree = true;
              overlays = openWebUIOverlays;
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
