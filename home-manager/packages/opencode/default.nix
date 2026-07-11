{
  lib,
  inputs,
  pkgs,
  ...
}:
let
  opencodeUnwrapped = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
  opencodeWrapped = pkgs.writeShellScriptBin "opencode" ''
    if [ -r /run/agenix/litellm-master-key ]; then
      set -a
      . /run/agenix/litellm-master-key
      set +a
    fi

    exec ${lib.getExe opencodeUnwrapped} "$@"
  '';
in
{
  programs.opencode = {
    enable = true;
    package = opencodeWrapped;
    tui.theme = "system";
    context = ''
      # Mandatory Rules

      ## In all languages
      - Prefer slightly verbose, self-explanatory code over terse code that needs
        comments to be understood.
      - Keep comments to only what explains something non-obvious.
      - Never embed a literal `\n` inside a string or print argument. A line break
        is always its own explicit statement. In C++/ROOT, use
        `std::cout << ... << std::endl;`. In Python, split output into separate
        `print()` calls, and use a bare `print()` for a blank line rather than
        appending `\n`.

      ## Nix
      - Always use flakes and flake-based commands (`nix run`, `nix shell`, etc.).
        Never use the old `nix-shell` approach.
      - If you are confused, stop and ask for help. This is especially critical in
        Nix.
      - Follow the existing style of the surrounding modules.

      ## C++ / ROOT
      - Use ROOT data types, and pick the *correct* one for the actual need rather
        than defaulting blindly: `Int_t` for ordinary ints, `Long64_t` for entry
        counts and large/64-bit values, `Double_t` for floating point, `TString`
        for string convenience, and so on. Match the width and signedness the code
        actually requires.
      - Do not use modern C++ features: no `auto`, no smart pointers, no
        range-based (`for (x : c)`) iteration. Use explicit types and classic
        indexed/iterator loops.
      - In performance-critical code, always gate logging behind a compile- or
        run-time toggle so it can be disabled. The `std::endl` flush is therefore
        never a concern on hot paths.

      ## Python
      - In Python that uses ROOT, never use matplotlib. Look at nearby files for the
        established plotting approach, or ask which is preferred.

      ## Explanations
      - For non-trivial changes, explain thoroughly what changed and why. Do not
      over-summarize or truncate the reasoning. Trivial edits can stay terse. 
    '';

    settings = {
      provider.litellm = {
        npm = "@ai-sdk/openai-compatible";
        name = "LiteLLM";
        options = {
          baseURL = "https://llm.ethanwtodd.com/v1";
          apiKey = "{env:LITELLM_MASTER_KEY}";
        };

        models = {
          "qwen3.6-35b-a3b-coding" = {
            options = {
              temperature = 0.6;
            };
          };

          "qwen3.6-27b-coding" = {
            options = {
              temperature = 0.6;
              topP = 0.95;
              topK = 20;
              minP = 0;
              presencePenalty = 0;
            };
          };

          "qwen3.6-27b-heretic-coding" = {
            options = {
              temperature = 0.6;
              topP = 0.95;
              topK = 20;
              minP = 0;
              presencePenalty = 0;
            };
          };

          "qwen3.6-27b-heretic-general" = {
            options = {
              temperature = 1.0;
              topP = 0.95;
              topK = 20;
              minP = 0;
              presencePenalty = 0;
            };
          };

          "gemma-4-31b-heretic" = {
            options = {
              temperature = 1.0;
              topP = 0.95;
              topK = 64;
            };
          };

          "qwen3.5-122b-a10b" = {
            options = {
              temperature = 0.6;
              topP = 0.95;
              topK = 20;
              minP = 0;
              presencePenalty = 0;
              repetitionPenalty = 1.0;
            };
          };

          "step-3.7-flash-low" = {
            options = {
              temperature = 0.7;
            };
          };

          "step-3.7-flash-medium" = {
            options = {
              temperature = 0.7;
            };
          };

          "step-3.7-flash-high" = {
            options = {
              temperature = 0.7;
            };
          };

          "qwen3-coder-next" = { };

          "nemotron-3-super-120b-a12b-no-thinking-coding" = {
            options = {
              temperature = 0.6;
            };
          };

          "nemotron-3-super-120b-a12b-thinking-coding" = {
            options = {
              temperature = 0.6;
            };
          };

          "deepseek-v4-flash-max" = {
          };

          "deepseek-v4-flash-high" = {
          };

          "deepseek-v4-flash-no-thinking" = {
          };

          "minimax-m2.7" = {
          };
        };
      };
      permission = {
        edit = "ask";
        bash = {
          "*" = "ask";
          "git status *" = "allow";
          "git diff *" = "allow";
          "git log *" = "allow";
          "grep *" = "allow";
          "rg *" = "allow";
          "ls *" = "allow";
          "ls -la *" = "allow";
        };
      };
      server.port = 4096;
      model = "litellm/qwen3.6-27b-coding";

      # fetch + SearXNG web_search + nixos lookups, served by the LiteLLM MCP
      # gateway on son-of-anton (the same tools LibreChat gets) — nixos used to
      # be a local `nix run` here but is now centralized on the gateway. Auth
      # via the master key.
      #    mcp.litellm = {
      #      type = "remote";
      #      url = "https://llm.ethanwtodd.com/mcp/";
      #      headers.Authorization = "Bearer {env:LITELLM_MASTER_KEY}";
      #      enabled = true;
      #    };
    };
  };
}
