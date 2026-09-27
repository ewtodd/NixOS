{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Upstream ships the packaging (nix/packages/*.nix) and a NixOS module
  # (nix/modules/bifrost.nix). Import the module file directly and build their
  # UI derivation with our pkgs: their flake pins staging-next and overlays Go
  # from source, while our lock already has go_1_27. The HTTP derivation is
  # adapted in-repo (pkgs/bifrost-http.nix) to pin our vendor hash.
  #
  # Same trick as hardware.asahi.pkgs on oracle: import nixpkgs as a cross set
  # (localSystem x86_64, crossSystem aarch64) so the derivation's build system
  # is x86_64 and e-desktop compiles it natively instead of emulating aarch64.
  # The UI is platform-independent JS, built by the build-platform set; only
  # the Go binary is cross-compiled.
  buildPkgs =
    if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then
      import pkgs.path {
        localSystem.system = "x86_64-linux";
        crossSystem.system = "aarch64-linux";
      }
    else
      pkgs;

  bifrostVersion = lib.strings.trim (builtins.readFile "${inputs.bifrost}/transports/version");

  bifrost-ui =
    (buildPkgs.buildPackages.callPackage "${inputs.bifrost}/nix/packages/bifrost-ui.nix" {
      src = inputs.bifrost;
      version = bifrostVersion;
    }).overrideAttrs
      (old: {
        # Upstream's npmDepsHash was computed against their staging-next npm; ours
        # resolves the lockfile to a different tree. Override the deps derivation
        # directly (npmDepsHash alone is inert here). A mismatch prints the
        # expected hash, so paste it here when the UI or nixpkgs moves.
        npmDeps = buildPkgs.buildPackages.fetchNpmDeps {
          name = "bifrost-ui-${bifrostVersion}-npm-deps";
          src = inputs.bifrost;
          sourceRoot = "source/ui";
          hash = "sha256-cOswnT4ZahWX66h9oiw4t3r5GZeOH/yjbnTCAsjVgnw=";
        };
      });

  bifrost-http = buildPkgs.callPackage ./pkgs/bifrost-http.nix {
    src = inputs.bifrost;
    version = bifrostVersion;
    inherit bifrost-ui;
  };

  sonOfAntonVllm = "http://10.0.0.5:8100"; # vLLM on R9700s (TP=2)
  sonOfAntonStrix = "http://10.0.0.5:8050"; # llama.cpp strix-halo, Qwen3.8-Flash-Next on the iGPU
  oracleSwap = "http://10.0.0.6:8080"; # llama-swap on this host

  arxiv-mcp-server = pkgs.callPackage ./pkgs/arxiv-mcp-server.nix {
    src = inputs.arxiv-mcp-server-src;
  };
  searxngMcpPython = pkgs.python3.withPackages (ps: [
    ps.mcp
    ps.httpx
  ]);

  # Owner and friend instances of the same gateway; the friend key is scoped to
  # the 27B by provider allowlist and a request-rate limit.
  mcpClients = [
    "fetch"
    "searxng"
    "nixos"
    "arxiv"
    "context7"
  ];
in
{
  imports = [ "${inputs.bifrost}/nix/modules/bifrost.nix" ];

  config = lib.mkIf config.systemOptions.services.bifrost.enable {
    services.bifrost = {
      enable = true;
      package = bifrost-http;
      host = "0.0.0.0";
      port = 4002;
      stateDir = "/var/lib/bifrost";
      logLevel = "info";
      logStyle = "json";
      openFirewall = true;

      # The searxng MCP script reads this and passes it through to the child.
      environment.SEARXNG_URL = "http://127.0.0.1:8888";

      # Every consumer has its own virtual key (bifrost-keys); admin auth,
      # the encryption key and the DeepSeek key live in bifrost-env.
      environmentFile = config.age.secrets.bifrost-env.path;

      settings = {
        # config.json is the source of truth, so removing a provider here (as
        # with the first vllm attempt) prunes it from the SQLite store instead
        # of leaving a stale row behind.
        source_of_truth = "config.json";

        client = {
          enforce_auth_on_inference = true;
          # son-of-anton and opencode fetch MCP tools themselves; do not also
          # attach them to every inference request.
          mcp_disable_auto_tool_inject = true;
        };

        providers = {
          # Custom openai-based provider rather than the standard vllm one:
          # the standard provider registers keys under vllm_key_config's
          # model_name and ignores models/aliases, so the logical name clients
          # use never resolves.
          vllm27b = {
            custom_provider_config = {
              base_provider_type = "openai";
              is_key_less = true;
            };
            network_config = {
              base_url = sonOfAntonVllm;
              allow_private_network = true;
              default_request_timeout_in_seconds = 1800;
            };
            keys = [
              {
                name = "qwen38-27b";
                value = "";
                models = [ "qwen3.8-27b" ];
                weight = 1.0;
              }
            ];
          };

          strix = {
            custom_provider_config = {
              base_provider_type = "openai";
              is_key_less = true;
            };
            network_config = {
              base_url = sonOfAntonStrix;
              allow_private_network = true;
              default_request_timeout_in_seconds = 1800;
            };
            keys = [
              {
                name = "qwen38-flash-next";
                value = "";
                models = [ "qwen3.8-flash-next" ];
                weight = 1.0;
              }
            ];
          };

          llamaswap = {
            custom_provider_config = {
              base_provider_type = "openai";
              is_key_less = true;
            };
            network_config = {
              base_url = oracleSwap;
              allow_private_network = true;
              default_request_timeout_in_seconds = 1800;
            };
            keys = [
              {
                name = "little-titles";
                value = "";
                models = [ "little-titles" ];
                weight = 1.0;
              }
            ];
          };

          deepseek = {
            keys = [
              {
                name = "deepseek-v4-api";
                value = "env.DEEPSEEK_API_KEY";
                models = [ "deepseek-v4-api" ];
                weight = 1.0;
                aliases."deepseek-v4-api" = "deepseek-flash";
              }
            ];
          };
        };

        # Stdio servers exposed through /mcp. They are only reachable through a
        # virtual key that lists them (mcp_configs).
        mcp.client_configs = [
          {
            name = "fetch";
            connection_type = "stdio";
            stdio_config = {
              command = lib.getExe pkgs.mcp-server-fetch;
              args = [ ];
            };
            auth_type = "none";
            tools_to_execute = [ "*" ];
          }
          {
            name = "searxng";
            connection_type = "stdio";
            stdio_config = {
              command = "${searxngMcpPython}/bin/python";
              args = [ "/etc/bifrost/searxng_mcp.py" ];
              envs = [ "SEARXNG_URL" ];
            };
            auth_type = "none";
            tools_to_execute = [ "*" ];
          }
          {
            name = "nixos";
            connection_type = "stdio";
            stdio_config = {
              command = lib.getExe pkgs.mcp-nixos;
              args = [ ];
            };
            auth_type = "none";
            tools_to_execute = [ "*" ];
          }
          {
            name = "arxiv";
            connection_type = "stdio";
            stdio_config = {
              command = lib.getExe arxiv-mcp-server;
              args = [
                "--storage-path"
                "/var/lib/bifrost/arxiv-papers"
              ];
            };
            auth_type = "none";
            tools_to_execute = [ "*" ];
          }
          {
            name = "context7";
            connection_type = "stdio";
            stdio_config = {
              command = lib.getExe pkgs.context7-mcp;
              args = [ ];
            };
            auth_type = "none";
            tools_to_execute = [ "*" ];
          }
        ];

        governance = {
          # Dashboard/management API login. Admin credentials are never
          # required on /v1; inference is guarded by virtual keys.
          auth_config = {
            is_enabled = true;
            admin_username = "env.BIFROST_ADMIN_USERNAME";
            admin_password = "env.BIFROST_ADMIN_PASSWORD";
          };

          # Explicitly empty: with source_of_truth=config.json a missing
          # section leaves stored rows alone, and older deploys seeded CEL
          # routing rules that cannot compile in this build.
          routing_rules = [ ];

          # Bare model names resolve to the single provider whose key `models`
          # lists them; custom (openai-based) providers forward the request
          # name verbatim and ignore aliases, so the upstreams must serve the
          # same names clients send (vLLM gets both spellings).
          virtual_keys = [
            {
              id = "opencode";
              name = "opencode";
              value = "env.BIFROST_OPENCODE_VK";
              allow_all_providers = true;
            }
            {
              id = "open-webui";
              name = "open-webui";
              value = "env.BIFROST_OPENWEBUI_VK";
              allow_all_providers = true;
            }
            {
              id = "soa";
              name = "son-of-anton";
              value = "env.BIFROST_SOA_VK";
              allow_all_providers = true;
              mcp_configs = map (name: {
                mcp_client_name = name;
                tools_to_execute = [ "*" ];
              }) mcpClients;
            }
            {
              id = "friend";
              name = "friend";
              value = "env.BIFROST_FRIEND_VK";
              rate_limit_id = "friend-rpm";
              provider_configs = [
                {
                  provider = "vllm27b";
                  allowed_models = [ "qwen3.8-27b" ];
                  key_ids = [ "*" ];
                }
              ];
            }
            {
              # Kept for local smoke tests.
              id = "spike";
              name = "spike";
              value = "env.BIFROST_SPIKE_VK";
              provider_configs = [
                {
                  provider = "vllm27b";
                  allowed_models = [ "qwen3.8-27b" ];
                  key_ids = [ "*" ];
                }
              ];
            }
          ];

          rate_limits = [
            {
              id = "friend-rpm";
              request_max_limit = 30;
              request_reset_duration = "1m";
            }
          ];
        };
      };
    };

    # Second EnvironmentFile for the per-consumer virtual keys, appended to the
    # module's single environmentFile.
    systemd.services.bifrost.serviceConfig.EnvironmentFile = lib.mkAfter [
      config.age.secrets.bifrost-keys.path
    ];

    environment.etc."bifrost/searxng_mcp.py".source = ./searxng_mcp.py;
  };
}
