{
  lib,
  pkgs,
  inputs,
  osConfig,
  config,
  ...
}:
let
  protonMCP = pkgs.buildNpmPackage {
    pname = "proton-mcp";
    version = "5.0.0";
    src = inputs.proton-mcp-src;
    nodejs = pkgs.nodejs;
    npmDepsHash = "sha256-KG/Nt0lY2w8VHGp6sOW1W0hkP89cuGnwzuhL8Db9dEQ=";
    dontNpmBuild = true;
  };
  entry = "${protonMCP}/lib/node_modules/proton-mcp/index.js";
  proton-mcp-wrapper = pkgs.writeShellScriptBin "proton-mcp" ''
    set -a
    . /run/agenix/proton-mail-bridge
    set +a
    exec ${pkgs.nodejs}/bin/node ${entry}
  '';
  opencodeWrapped = pkgs.writeShellScriptBin "opencode" ''
    if [ -r /run/agenix/bifrost-keys ]; then
      set -a
      . /run/agenix/bifrost-keys
      set +a
    fi
    exec ${lib.getExe inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode} "$@"
  '';
  # AMD's agent skills, pinned by rev+hash. The rocm-systems monorepo is
  # ~7.6 GB, so sparseCheckout keeps the fetch to the skill directories.
  amdSkills = pkgs.fetchFromGitHub {
    owner = "amd";
    repo = "skills";
    rev = "6efb39c7ec59f19823372cb22ee3b8fac82dffd7";
    hash = "sha256-eX+UJgCxetrQ28fDNs221Q2fpkrLOyLh5WvIIpJlZjE=";
  };
  rocmSkills = pkgs.fetchgit {
    url = "https://github.com/ROCm/rocm-systems";
    rev = "a970e27caab941004c8c55d109d776d01489c89d";
    sparseCheckout = [
      "projects/rocprofiler-compute/skills"
      "projects/rocprofiler-sdk/skills"
    ];
    fetchSubmodules = false;
    hash = "sha256-5+eYbYF+qoP4+3ULUslpI05McEZVpbMiVJfEfkiBK4U=";
  };
in
{
  programs.opencode = {
    enable = true;
    package = opencodeWrapped;
    tui.theme = "system";
    skills = {
      magpie-kernel-evaluator = "${amdSkills}/skills/magpie-kernel-evaluator";
      rocm-doctor = "${amdSkills}/staging/rocm-doctor";
      quark-torch-llm-ptq = "${amdSkills}/skills/quark-torch-llm-ptq";

      rocprof-compute-kernel-bottleneck = "${rocmSkills}/projects/rocprofiler-compute/skills/rocprof-compute-kernel-bottleneck";
      rocprof-compute-pc-sampling = "${rocmSkills}/projects/rocprofiler-compute/skills/rocprof-compute-pc-sampling";
      rocprof-compute-roofline = "${rocmSkills}/projects/rocprofiler-compute/skills/rocprof-compute-roofline";
      pc-sampling = "${rocmSkills}/projects/rocprofiler-sdk/skills/pc-sampling";
    };
    context = ''
      # Mandatory Rules

       ## Tools 
       - Use ripgrep (rg) instead of grep for searches; it is much faster. 
       - Unless told otherwise, use "son-of-anton-bot <307402699+son-of-anton-bot@users.noreply.github.com>"
         as the author/committer when asked to git commit.

       ## In all languages
       - Prefer slightly verbose, self-explanatory code over terse code that needs
         comments to be understood.
       - Keep comments to only what explains something non-obvious. Two lines at 
         the maximum.
       - Never build/run code unless explicitly asked.
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
       - Before guessing or scraping search.nixos.org, look up nixpkgs/NixOS/Home
         Manager/Darwin options and packages with the `nixos` MCP tools (`nixos_nix`,
         `nixos_nix_versions`): action=search with type=options for options,
         action=info for a specific path.

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
    '';

    settings = {
      experimental.openTelemetry = false;
      enabled_providers = [
        "bifrost"
        "deepseek"
      ];

      model = "bifrost/qwen3.8-27b";
      small_model = "bifrost/little-titles";
      default_agent = "build";

      agent = {
        compaction = {
          model = "deepseek/deepseek-flash";
        };
        build = {
          variant = "low";
          description = "Coding agent; the default. Fast interactive model (qwen3.8).";
          prompt = ''
            You are a coding agent in a terminal. Work tasks through end to end:
            inspect the code, edit files, run commands, verify. Use the questions tool if you need more 
            information. Keep prose brief; the rules in AGENTS.md carry the style details.
          '';
        };
        plan = {
          model = "bifrost/qwen3.8-27b";
          variant = "xhigh";
          description = "Plans and designs before acting. Deep thinking model (qwen3.8-27b).";
          permission = {
            edit = "deny";
          };
          prompt = ''
            You are a planning agent. Read whatever code you need — your context
            is huge, use it. Then ship a plan that is a handoff contract for an
            executor who has only this plan and the task: exact file paths,
            symbols, what changes in each file, the order, and how to verify.
            Do not dump exploration or full file contents into the plan; keep it
            distilled. Do not edit anything.
          '';
        };
        execute = {
          model = "bifrost/qwen3.8-27b";
          variant = "low";
          description = "Executes a plan or task with the fast model (qwen3.8).";
          prompt = ''
            You are the executor. You get a task and, usually, a plan from the
            planning agent. Follow the plan exactly: read the files it names,
            edit, run, verify. Do not re-explore the repo — the plan already
            did. Keep your context small: read targeted ranges, not whole
            files. If a plan step is missing, make the smallest sensible
            choice and say so. Report what you changed and how you verified.
          '';
        };
        explore = {
          model = "bifrost/qwen3.8-27b";
          variant = "low";
          description = "Finds and reads code. Fast low-think qwen; returns file:line evidence.";
          permission = {
            edit = "deny";
          };
          prompt = ''
            You are a search agent. Answer with evidence: file:line references
            gathered with grep/glob/read. Return findings as a short list plus
            a one-line summary. Never edit; run commands only when needed to
            locate things.
          '';
        };
        general = {
          model = "bifrost/qwen3.8-flash-next";
          variant = "medium";
          description = "Runs self-contained multi-step tasks and returns a final report (qwen3.8-27b).";
          prompt = ''
            You are a worker subagent. You get one self-contained task; finish
            it with your tools and return a single final report. Do not ask the
            caller to do anything you can do yourself.
          '';
        };
        reviewer = {
          model = "bifrost/qwen3.8-flash-next";
          variant = "xhigh";
          description = "Reviews diffs and code for problems, fixes what it finds. Qwen3.8-Flash-Next (177B) on the Strix iGPU.";
          prompt = ''
            You are a code reviewer. Read the change and its surroundings.
            Report problems by severity, each with file:line: correctness,
            edge cases, AGENTS.md violations, dead code, missing tests. Be
            specific and cold. Fix what you find, then verify.
          '';
        };
        commit = {
          hidden = true;
          description = "Use to accurately summarize uncommitted git changes, and then commit them.";
          prompt = ''
            You are a summarization agent. Your job is to review all uncommitted git changes in the
            current repository, write an accurate commit message matching the existing style, and then 
            stage+commit them. Commit using your account: 
            son-of-anton-bot <307402699+son-of-anton-bot@users.noreply.github.com>'';
          model = "bifrost/qwen3.8-27b";
          variant = "low";
        };
      };
      command = {
        commit = {
          template = ''
            You are a summarization agent. Your job is to review all uncommitted git changes in the
            current repository, write an accurate commit message matching the existing style, and then 
            stage+commit them. Commit using your account: 
            son-of-anton-bot <307402699+son-of-anton-bot@users.noreply.github.com>'';
          description = "Automated git commit.";
          agent = "commit";
        };
      };
      provider = {
        bifrost = {
          npm = "@ai-sdk/openai-compatible";
          name = "Bifrost";
          options = {
            baseURL = "https://llm.ethanwtodd.com/v1";
            apiKey = "{env:BIFROST_OPENCODE_VK}";
          };
          models = {
            "little-titles" = {
              name = "Little Titles (do not select!)";
              tool_call = false;
            };

            "qwen3.8-27b" = {
              name = "Qwen3.8 27B";
              variants = {
                xhigh = {
                  reasoningEffort = "xhigh";
                };
                medium = {
                  reasoningEffort = "medium";
                };
                low = {
                  reasoningEffort = "low";
                };
                none = {
                  chat_template_kwargs = {
                    enable_thinking = false;
                  };
                };
              };
              modalities = {
                input = [
                  "text"
                  "image"
                ];
                output = [ "text" ];
              };
            };

            "qwen3.8-flash-next" = {
              name = "Qwen3.8 Flash Next";
              variants = {
                xhigh = {
                  reasoningEffort = "xhigh";
                };
                medium = {
                  reasoningEffort = "medium";
                };
                low = {
                  reasoningEffort = "low";
                };
                none = {
                  chat_template_kwargs = {
                    enable_thinking = false;
                  };
                };
              };
              modalities = {
                input = [
                  "image"
                  "text"
                ];
                output = [ "text" ];
              };
            };

          };
        };
      };
      mcp = {
        # Local Nix option/package search. Kept local (not the Bifrost gateway)
        # so it works independent of oracle's reachability.
        nixos = {
          type = "local";
          command = [ "${lib.getExe pkgs.mcp-nixos}" ];
          enabled = true;
        };
        # Web search through the gateway's aggregate endpoint. The opencode
        # key's MCP grant (bifrost module) narrows /mcp to the mcp-searxng
        # tools, so the other MCP servers stay invisible. BIFROST_OPENCODE_VK
        # comes from the opencode wrapper's secret.
        searxng = {
          type = "remote";
          url = "https://llm.ethanwtodd.com/mcp";
          headers = {
            Authorization = "Bearer {env:BIFROST_OPENCODE_VK}";
          };
          enabled = true;
        };
        proton =
          # surely there's a better way to do this!
          lib.mkIf
            (
              osConfig.systemOptions.owner.e.enable
              && osConfig.systemOptions.deviceType.desktop.enable
              && config.Profile == "play"
            )
            {
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
