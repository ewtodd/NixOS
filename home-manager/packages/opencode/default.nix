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
      # Available Subagents

      You have access to specialized agents via the Task tool. Delegate to them
      when the task matches their expertise:

      - **code-reviewer** — Reviews code for bugs, security, performance, and
        maintainability. Read-only; use before committing or after a large change.
      - **security-auditor** — Deep security audit. Use when handling auth, crypto,
        secrets, or user input. Read-only.
      - **debugger** — Systematic root-cause analysis. Use when something is broken
        and the fix is not immediately obvious.
      - **architect** — High-level design decisions, module boundaries, API contracts.
        Read-only; use before starting a large feature.
      - **test-writer** — Generates comprehensive tests. Use after implementing a
        feature or bug fix.
      - **refactorer** — Improves code structure without changing behavior. Use when
        code is working but needs cleanup.
      - **docs-writer** — Writes documentation, docstrings, and READMEs.

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
        indexed/iterator loops. No lambdas!
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
          "qwen3.6-35b-a3b-coding" = { };
          "qwen3.6-27b-coding" = { };
          "qwen3.6-27b-heretic-coding" = { };
          "qwen3.5-122b-a10b" = { };
          "deepseek-v4-flash-max" = { };
          "deepseek-v4-flash-high" = { };
          "deepseek-v4-flash-no-thinking" = { };
          "fast-gemma-4-12b-it" = { };
          "fast-qwen3.6-27b" = { };
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

      agent = {
        explore = {
          mode = "subagent";
          model = "litellm/fast-gemma-4-12b-it";
        };
        compaction = {
          model = "litellm/fast-gemma-4-12b-it";
        };

        code-reviewer = {
          mode = "subagent";
          model = "litellm/qwen3.6-35b-a3b-coding";
          prompt = ''
            You are a code reviewer. Focus on security, performance, correctness, and maintainability.
            Point out bugs, edge cases, race conditions, and anti-patterns.
            Suggest concrete improvements with code examples.
            Do not modify files; only read and report.
          '';
          tools = {
            write = false;
            edit = false;
          };
        };

        security-auditor = {
          mode = "subagent";
          model = "litellm/qwen3.5-122b-a10b";
          prompt = ''
            You are a security auditor. Thoroughly analyze code for vulnerabilities:
            injection, XSS, CSRF, auth bypass, insecure defaults, hardcoded secrets,
            privilege escalation, and supply-chain risks.
            Rate findings by severity. Do not modify files.
          '';
          tools = {
            write = false;
            edit = false;
          };
        };

        debugger = {
          mode = "subagent";
          model = "litellm/deepseek-v4-flash-high";
          prompt = ''
            You are a debugger. Given a bug report, error trace, or misbehaving code,
            systematically trace the root cause. Read relevant files, reason about
            control flow and state, and propose a minimal fix.
            Explain your reasoning step by step before suggesting changes.
          '';
        };

        architect = {
          mode = "subagent";
          model = "litellm/qwen3.5-122b-a10b";
          prompt = ''
            You are a software architect. Help with high-level design decisions,
            module boundaries, data flow, and API contracts.
            Focus on maintainability, extensibility, and clear separation of concerns.
            Use diagrams (ASCII/mermaid) when helpful. Do not modify files.
          '';
          tools = {
            write = false;
            edit = false;
          };
        };

        test-writer = {
          mode = "subagent";
          model = "litellm/fast-qwen3.6-27b";
          prompt = ''
            You are a test writer. Generate comprehensive tests for the given code:
            unit tests, edge cases, boundary conditions, and error paths.
            Match the existing test framework and style in the codebase.
          '';
        };

        refactorer = {
          mode = "subagent";
          model = "litellm/deepseek-v4-flash-max";
          prompt = ''
            You are a refactoring specialist. Improve code structure without changing
            external behavior. Reduce duplication, simplify control flow, extract
            functions, and improve naming. Preserve existing tests and interfaces.
            Explain each refactoring step and its rationale.
          '';
        };

        docs-writer = {
          mode = "subagent";
          model = "litellm/fast-qwen3.6-27b";
          prompt = ''
            You are a technical writer. Create clear, accurate documentation:
            README files, docstrings, API references, and usage examples.
            Match the tone and structure of existing docs in the project.
          '';
        };
      };

      # fetch + SearXNG web_search + nixos lookups, served by the LiteLLM MCP
      # gateway on son-of-anton (the same tools LibreChat gets) — nixos used to
      # be a local `nix run` here but is now centralized on the gateway. Auth
      # via the master key.
      mcp.litellm = {
        type = "remote";
        url = "https://llm.ethanwtodd.com/mcp/";
        headers.Authorization = "Bearer {env:LITELLM_MASTER_KEY}";
        enabled = true;
      };
    };
  };
}
