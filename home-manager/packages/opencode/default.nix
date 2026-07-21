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
