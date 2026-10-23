# NixOS fleet — notes for agents
<!---->
README.md covers layout, hosts, `systemOptions`, and Colmena deployment.
<!---->
## Editing the configuration
- Don't write comments that restate the Nix.
  A reader who knows Nix and the module system can read what an option or
  expression does; explain why in the commit body instead.
- Comment only where the code cannot tell such a reader something they need:
  - a function you define: what it takes, what it returns, and any precedence or
    failure behaviour callers rely on;
  - a builtin or lib function that is easy to misread (`builtins.tryEval`
    swallowing errors, `lib.recursiveUpdate` replacing lists, `mkBefore` /
    `mkOrder`, `overrideAttrs` vs an extension);
  - a value that looks wrong or arbitrary and must not be "fixed": a deliberate
    exclusion, a non-default port, an upstream workaround (link it).
- Anything else gets no comment.
  When you change a commented line, update the comment or delete it.
  No commented-out code; git has it.
- Example (modules/services/son-of-anton/default.nix):

      # Needed: a defined function whose tryEval silently drops servers that
      # fail to evaluate.
      # The language servers nixvim enables, so the agent's post-write LSP
      # diagnostics run the same servers as the editor. Read from nixvim's
      # lsp.servers (one entry per server, no renamed aliases); entries that
      # fail to evaluate are skipped rather than breaking the build.
      nvimLspPackages = …;

      # Not needed: the option name says it all.
      keep-going = true;
<!---->
## Commits
- A lowercase summary line, `scope: change` (scope = host, service, or input),
  then a blank line, then a body that explains what changed and why.
  Not
  Conventional Commits.
  Some older commits cram everything into one long
  subject line; don't copy them.
- Agent commits: `--author="son-of-anton-bot <307402699+son-of-anton-bot@users.noreply.github.com>"`.
  Don't change the repo's git config. Do not add co-authored trailers.
<!---->
## Son of Anton instances (e-desktop)
- Settings live in `hosts/e-desktop/configuration.nix` under
  `systemOptions.services.son-of-anton`: shared `settings` (every instance and
  each account's CLI) and `instances.<name>.settings`, deep-merged over it.
- `modules/services/son-of-anton/default.nix` sets
  `pruneUnmanagedSettings = true`: activation deletes any `config.toml` key Nix
  does not declare, and `son-of-anton config set` refuses.
  Change settings
  here, never in `~/.son-of-anton/config.toml`.
- Each top-level key (`model`, `cron`, `security`, `delegation`, `memory`,
  `custom_providers`, …) is a sibling at the top of `settings`.
  Nested inside
  `model = { … }` it is silently ignored (fixed once in 16021894).
  After a
  deploy, check the generated `config.toml`'s top-level tables.
<!---->
## Deploying
- e-desktop and e-laptop deploy with `nrs` (`nh os switch /etc/nixos`); other
  hosts with `colmena apply --on <host1>,<host2>`.
  Never `sudo nixos-rebuild switch`.
- The son-of-anton package is the `son-of-anton` flake input pinned in
  `flake.lock`.
  Pushing son-of-anton does nothing until `nix flake update
  son-of-anton`, a commit of `flake.lock`, and `nrs` on e-desktop.
- Activation restarts changed `son-of-anton-<instance>` units; an open CLI
  keeps the old code until relaunched (`son-of-anton -c` resumes the session).
