{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Proton MCP server: talks to Proton Mail Bridge (IMAP/SMTP on localhost)
  # to expose Mail tools (list/delete/move/reply, etc.) to opencode.
  protonMCP = pkgs.buildNpmPackage {
    pname = "proton-mcp";
    version = "1.0.0";
    src = inputs.proton-mcp-src;
    nodejs = pkgs.nodejs;
    npmDepsHash = "sha256-c6iNdB2Z84sOWETluJJhZdhPicWR9esL9SPi50CA7zo=";
    dontNpmBuild = true;
  };
  entry = "${protonMCP}/lib/node_modules/proton-mcp/index.js";
  # Wrapper: opencode launches this; it sources the agenix-decrypted bridge
  # credentials (KEY=VALUE lines) then execs the MCP server. Keeps the
  # password out of the world-readable opencode config in the nix store.
  proton-mcp-wrapper = pkgs.writeShellScriptBin "proton-mcp" ''
    set -a
    . /run/agenix/proton-mail-bridge
    set +a
    exec ${pkgs.nodejs}/bin/node ${entry}
  '';
  # Wrapper: sources the agenix-decrypted LiteLLM master key so the
  # {env:LITELLM_MASTER_KEY} reference in the provider config resolves,
  # then execs the real opencode.
  opencodeWrapped = pkgs.writeShellScriptBin "opencode" ''
    if [ -r /run/agenix/litellm-master-key ]; then
      set -a
      . /run/agenix/litellm-master-key
      set +a
    fi
    exec ${lib.getExe pkgs.opencode} "$@"
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
       - Lambdas are permitted where they are short, local, and improve readability
         over the alternatives: sort comparators defined next to the std::sort call,
         thread workers whose explicit parameter lists would be longer and harder to
         scan than an inline capture. A lambda that spans more than about 5 lines or
         captures by reference outside an immediately obvious scope (e.g. stored in a
         std::function returned from the function) should still be a named function.
         When in doubt, write a named function.
       - In performance-critical code, always gate logging behind a compile- or
         run-time toggle so it can be disabled. The `std::endl` flush is therefore
         never a concern on hot paths.

       ## Python
       - In Python that uses ROOT, never use matplotlib. Look at nearby files for the
         established plotting approach, or ask which is preferred.

       ## Explanations
       - For non-trivial changes, explain thoroughly what changed and why. Do not
       over-summarize or truncate the reasoning. Trivial edits can stay terse. 

       ## git
       - Git conventions: renco-bot is the SOLE author of all commits in the temple repo — always commit there with:
         git -c user.name=renco-bot -c user.email=307402699+renco-bot@users.noreply.github.com commit -m \"...\"
         (no Co-authored-by trailer). Where his key exists (/var/lib/temple/renco_bot_github), also push with: 
         git -c core.sshCommand=\"ssh -i /var/lib/temple/renco_bot_github -o IdentitiesOnly=yes\" push
         Otherwise, just try to push normally. Only commit and push without being asked to in the temple repo.
    '';

    settings = {
      model = "litellm/deepseek-v4-flash";
      provider = {
        # Public gateway via the bastion: works off-LAN. /v1 paths bypass
        # anubis (litellm's master key is the auth) — see reverse-proxy.
        litellm = {
          npm = "@ai-sdk/openai-compatible";
          name = "LiteLLM";
          options = {
            baseURL = "https://litellm.ethanwtodd.com/v1";
            apiKey = "{env:LITELLM_MASTER_KEY}";
          };
          models = {
            "qwen3.6-27b-coding" = {
              name = "Qwen3.6 27B Coding";
            };
            "qwen3.6-27b-heretic-coding" = {
              name = "Qwen3.6 27B Heretic";
            };
            "gemma-4-31b" = {
              name = "Gemma 4 31B";
            };
            "deepseek-v4-flash" = {
              name = "Deepseek V4 Flash";
              variants = {
                max = {
                  reasoning_effort = "max";
                };
                high = {
                  reasoning_effort = "high";
                };
                none = {
                  chat_template_kwargs = {
                    enable_thinking = false;
                  };
                };
              };
            };
            "deepseek-v4-flash-full" = {
              name = "Deepseek V4 Flash (full precision)";
              variants = {
                max = {
                  reasoning_effort = "max";
                };
                high = {
                  reasoning_effort = "high";
                };
                none = {
                  chat_template_kwargs = {
                    enable_thinking = false;
                  };
                };
              };
            };
          };
        };
      };
      mcp = {
        proton = {
          type = "local";
          command = [ "${proton-mcp-wrapper}/bin/proton-mcp" ];
          enabled = true;
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
    };
  };
}
