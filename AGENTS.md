# NixOS fleet — notes for agents

README.md covers layout, hosts, `systemOptions`, and Colmena deployment.

## Commits
- A lowercase summary line, `scope: change` (scope = host, service, or input),
  then a blank line, then a body that explains what changed and why. Not
  Conventional Commits. Some older commits cram everything into one long
  subject line; don't copy them.
- Agent commits: `--author="son-of-anton-bot <307402699+son-of-anton-bot@users.noreply.github.com>"`.
  Don't change the repo's git config.

## Son of Anton instances (e-desktop)
- Settings live in `hosts/e-desktop/configuration.nix` under
  `systemOptions.services.son-of-anton`: shared `settings` (every instance and
  each account's CLI) and `instances.<name>.settings`, deep-merged over it.
- `modules/services/son-of-anton/default.nix` sets
  `pruneUnmanagedSettings = true`: activation deletes any `config.toml` key Nix
  does not declare, and `son-of-anton config set` refuses. Change settings
  here, never in `~/.son-of-anton/config.toml`.
- Each top-level key (`model`, `cron`, `security`, `delegation`, `memory`,
  `custom_providers`, …) is a sibling at the top of `settings`. Nested inside
  `model = { … }` it is silently ignored (fixed once in 16021894). After a
  deploy, check the generated `config.toml`'s top-level tables.

## Deploying
- e-desktop and e-laptop deploy with `nrs` (`nh os switch /etc/nixos`); other
  hosts with `colmena apply --on <host1>,<host2>`. Never `sudo nixos-rebuild switch`.
- The son-of-anton package is the `son-of-anton` flake input pinned in
  `flake.lock`. Pushing son-of-anton does nothing until `nix flake update
  son-of-anton`, a commit of `flake.lock`, and `nrs` on e-desktop.
- Activation restarts changed `son-of-anton-<instance>` units; an open CLI
  keeps the old code until relaunched (`son-of-anton -c` resumes the session).
