# Run by flake-bump.service as the repo owner. Updates every input on a fresh
# branch in its own worktree, builds every host there, diffs the closures and
# scans the public hosts for CVEs, then leaves report.md and a PENDING marker
# for the son-of-anton review job. main and its working tree are never touched.
set -E

repo=${FLAKE_BUMP_REPO:?}
state=${STATE_DIRECTORY:?}
date=$(date +%F)
runs=$state/runs
run=$runs/$date
wt=$state/worktree
branch=flake-bump/$date
author="son-of-anton-bot <307402699+son-of-anton-bot@users.noreply.github.com>"
public_hosts=(nu mu)

rm -rf "$run"
mkdir -p "$run"

fail() {
  {
    printf '# Flake update %s: the run itself failed\n\n' "$date"
    printf 'flake-bump.service stopped at line %s of its script. ' "$1"
    printf 'Its journal (journalctl -u flake-bump) has the details.\n'
  } >"$run/report.md"
  touch "$run/PENDING"
}
trap 'fail $LINENO' ERR

git -C "$repo" worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"
git -C "$repo" worktree prune
while read -r b; do
  git -C "$repo" branch -D "$b" >/dev/null
done < <(git -C "$repo" for-each-ref --format='%(refname:short)' 'refs/heads/flake-bump/*')
base=$(git -C "$repo" rev-parse main)
git -C "$repo" worktree add -q -b "$branch" "$wt" "$base"
cd "$wt"

attr() { printf '.#nixosConfigurations.%s.config.system.build.toplevel' "$1"; }
mapfile -t hosts < <(nix eval --json .#nixosConfigurations --apply builtins.attrNames | jq -r '.[]')

# The closures main builds, where they are already in the store; a host
# without one gets no version diff rather than a full rebuild of the old.
declare -A old new
for h in "${hosts[@]}"; do
  p=$(nix eval --raw "$(attr "$h").outPath" 2>/dev/null || true)
  if [ -n "$p" ] && [ -e "$p" ]; then old[$h]=$p; fi
done

nix flake update 2>"$run/update.log"
if git diff --quiet -- flake.lock; then
  printf '# Flake update %s\n\nNo input moved since main (%s).\n' "$date" "${base:0:8}" >"$run/report.md"
  exit 0
fi
mapfile -t moved < <(grep -oE "Updated input '[^']+'" "$run/update.log" | sed -E "s/Updated input '([^']+)'/\1/" | sort -u)

failed=()
for h in "${hosts[@]}"; do
  if nix build "$(attr "$h")" --out-link "$run/new-$h" >"$run/build-$h.log" 2>&1; then
    new[$h]=$(readlink -f "$run/new-$h")
  else
    failed+=("$h")
  fi
done

for h in "${!new[@]}"; do
  if [ -n "${old[$h]:-}" ]; then
    nvd --color never diff "${old[$h]}" "${new[$h]}" >"$run/nvd-$h.txt" 2>&1 || true
  fi
done

# vulnix exits 2 when it finds anything, so only its output counts.
high() {
  jq -r '.[] | . as $p | (.cvssv3_basescore // {}) | to_entries[]
    | select(.value >= 7) | "\(.key) \(.value) \($p.pname) \($p.version)"' "$1" 2>/dev/null | sort -u
}
for h in "${public_hosts[@]}"; do
  [ -n "${new[$h]:-}" ] || continue
  timeout 45m vulnix --json "${new[$h]}" >"$run/vulnix-$h-new.json" 2>>"$run/vulnix-$h.err" || true
  high "$run/vulnix-$h-new.json" >"$run/cves-$h-new.txt"
  if [ -n "${old[$h]:-}" ]; then
    timeout 45m vulnix --json "${old[$h]}" >"$run/vulnix-$h-old.json" 2>>"$run/vulnix-$h.err" || true
    high "$run/vulnix-$h-old.json" >"$run/cves-$h-old.txt"
  fi
done

committed=no
if [ ${#failed[@]} -eq 0 ]; then
  git add flake.lock
  git commit -q --author="$author" -F - <<EOF
flake: weekly update ($date)

The scheduled update (flake-bump.service) moved every input that had new
commits: $(printf '%s, ' "${moved[@]}" | sed 's/, $//').
Every host's system builds with the new lock.
EOF
  committed=yes
fi

{
  printf '# Flake update %s\n\n' "$date"
  printf 'Branch `%s` in the worktree `%s`, from main at %s. ' "$branch" "$wt" "${base:0:8}"
  if [ "$committed" = yes ]; then
    printf 'flake.lock is committed there.\n\n'
  else
    printf 'flake.lock is updated there but not committed, since a host failed to build.\n\n'
  fi
  printf 'Run files (build logs, full nvd diffs, vulnix JSON): `%s`\n\n' "$run"

  printf '## Inputs moved\n\n```\n'
  grep -vE '^warning:' "$run/update.log" || true
  printf '```\n\n## Builds\n\n'
  for h in "${hosts[@]}"; do
    if [ -n "${new[$h]:-}" ]; then
      if [ "${old[$h]:-}" = "${new[$h]}" ]; then
        printf -- '- %s: builds, closure unchanged\n' "$h"
      elif [ -z "${old[$h]:-}" ]; then
        printf -- '- %s: builds (no old closure in the store to compare)\n' "$h"
      else
        printf -- '- %s: builds, closure changed\n' "$h"
      fi
    else
      printf -- '- %s: **FAILED** (`%s`)\n' "$h" "$run/build-$h.log"
    fi
  done
  for h in "${failed[@]}"; do
    printf '\n### %s build log (last 40 lines)\n\n```\n' "$h"
    tail -n 40 "$run/build-$h.log"
    printf '```\n'
  done

  printf '\n## Version changes\n\nUpgrades and downgrades per host; the full diffs are `nvd-<host>.txt`.\n'
  for h in "${hosts[@]}"; do
    [ -s "$run/nvd-$h.txt" ] || continue
    printf '\n### %s\n\n```\n' "$h"
    grep -E '^\[[UD]' "$run/nvd-$h.txt" | head -n 60 || true
    grep -E '^Closure size' "$run/nvd-$h.txt" || true
    printf '```\n'
  done

  printf '\n## CVEs with CVSS >= 7 (vulnix)\n'
  for h in "${public_hosts[@]}"; do
    [ -e "$run/cves-$h-new.txt" ] || continue
    printf '\n### %s\n\n' "$h"
    if [ -e "$run/cves-$h-old.txt" ]; then
      printf 'Fixed by this update:\n\n```\n'
      comm -23 <(cut -d' ' -f1 "$run/cves-$h-old.txt" | sort -u) <(cut -d' ' -f1 "$run/cves-$h-new.txt" | sort -u) || true
      printf '```\n\n'
    fi
    printf 'Still open after it:\n\n```\n'
    cat "$run/cves-$h-new.txt"
    printf '```\n'
    if [ -s "$run/vulnix-$h.err" ]; then
      printf '\nvulnix stderr: `%s`\n' "$run/vulnix-$h.err"
    fi
  done

  cat <<EOF

## For the reviewer

Ethan deploys; you never do (no nrs, no colmena, no git push). Work in the
worktree above, never in /etc/nixos's own checkout, and commit nothing.

1. Failed builds: read each log, find the cause (an upstream change, or this
   repo's overlays and modules), and describe the fix you would make.
2. Public services (Nextcloud, Collabora, Open WebUI, Grafana, Caddy, Anubis,
   Paper, OpenSSH, the kernels): for each version jump above, read the
   upstream release notes and the NixOS module's changes for breaking changes
   or manual steps. A Nextcloud major must go one major at a time.
3. Ethan's own inputs among those moved (son-of-anton, eklow, unholy, gufo,
   radiance-nix, maitred, llmtop, website, lifer, and the like): read each
   one's commits in the moved range, cloned fresh into /tmp as AGENTS.md
   says, and flag renamed config keys, port or model changes, and anything
   that needs a migration or a matching change in this repo.
4. Reply with a verdict (deploy, deploy with care, or hold), the reasons, the
   CVEs fixed and still open, and the commands, in order:
   - git -C /etc/nixos merge --ff-only $branch
     (if main has moved since ${base:0:8}, say so: the branch then needs a
     rebase onto main, and a rebuild check, before it merges)
   - nrs, on e-workstation
   - colmena apply --on <the servers whose closure changed>, one YubiKey
     touch per host
   - e-laptop, v-desktop and v-laptop take it at their own next rebuild.
EOF
} >"$run/report.md"

touch "$run/PENDING"

find "$runs" -mindepth 1 -maxdepth 1 -type d | sort | head -n -4 | xargs -r rm -rf
