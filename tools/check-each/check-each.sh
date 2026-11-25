#!/usr/bin/env bash
# check-each: run every check of this flake one at a time, each in its own process
# under a memory ceiling, instead of all inside one `nix flake check`.
#
# Why: `nix flake check` evaluates every check in a single Nix process, so its memory
# is roughly the SUM of all the evaluations, and that process grew past 10 GiB (killed
# by the kernel at a 10 GiB cap on 2026-11-25, 27 checks, the largest of which needs
# about 5 GiB alone). Here each check gets a fresh process that ends before the next
# one starts, so the peak is the largest single check, and the check that hits the
# ceiling is named. Slower (about five minutes for the 27 checks on `nixos`), by choice.
#
#   check-each [OPTIONS] [CHECK...]
#
#   CHECK...      only these checks (names as `--list` prints them); none: all of them
#   --list        print the checks that would run, and stop
#   --skip NAME   leave this check out (repeatable)
#   --cap SIZE    the memory ceiling of each check, as systemd takes it (default 6G;
#                 swap is off, so a check that needs more is killed, not slowed down)
#   --no-cap      run without a ceiling: only for a machine with no systemd user session,
#                 and with the memory to spare. Without this flag a missing or unusable
#                 systemd-run is an error, never a silent uncapped run.
#   --cores N     `nix build --cores` for each check (default 2); one job at a time
#   --no-outputs  do not evaluate the flake's other outputs (see below)
#   --flake REF   the flake (default .; a worktree's new files need `git add`)
#   --system S    the system whose checks to run (default: this machine's)
#   --logs DIR    keep each step's full log here (default: a temporary directory,
#                 removed when everything passed)
#
# After the checks, unless CHECKs were named, the other outputs `nix flake check` would
# also evaluate are evaluated one by one in the same way: homeModules, nixosModules,
# templates, lib (their attribute names), packages and devShells (each derivation's
# path), apps (each program) and the formatter. One the flake does not have is skipped.
# That is a lighter test than `nix flake check`'s own (the checks exercise the modules
# properly); it is here so that the structure of the outputs is still looked at.
#
# Each step prints one line as it ends: ok, FAIL (with the tail of its log), or KILLED.
# KILLED means the process got SIGKILL (exit 137), which at a memory ceiling is the
# kernel running out of the allowance: that check was NOT RUN, which is neither a pass
# nor a failure of the code. If it is the ceiling, raise --cap or lighten the check.
#
# Exit status: 0 everything passed; 1 something failed; 3 nothing failed but something
# was KILLED (not run); 2 a usage or setup problem (nothing was run).
set -u

usage() { sed -n '/^#   check-each/,/^# Exit status/p' "$0" | sed 's/^# \{0,1\}//' >&2; }

flake=.
system=
cap=6G
cores=2
use_cap=1
outputs=1
logs=
list=
want=()
skip=()
while (($#)); do
  case $1 in
    --flake) flake=${2:?--flake needs a flake reference}; shift 2 ;;
    --system) system=${2:?--system needs a system name}; shift 2 ;;
    --cap) cap=${2:?--cap needs a size, such as 6G}; shift 2 ;;
    --no-cap) use_cap=; shift ;;
    --cores) cores=${2:?--cores needs a number}; shift 2 ;;
    --skip) skip+=("${2:?--skip needs a check name}"); shift 2 ;;
    --no-outputs) outputs=; shift ;;
    --logs) logs=${2:?--logs needs a directory}; shift 2 ;;
    --list) list=1; shift ;;
    -h | --help) usage; exit 0 ;;
    -*) echo "check-each: unknown option $1" >&2; usage; exit 2 ;;
    *) want+=("$1"); shift ;;
  esac
done

if [ -n "$use_cap" ]; then cap_text=$cap; else cap_text="no limit"; fi

# Everything heavy goes through here. systemd-run puts the command in its own scope
# with the memory ceiling and no swap; nice keeps the desktop usable meanwhile.
capped() {
  if [ -n "$use_cap" ]; then
    systemd-run --user --scope --quiet -p "MemoryMax=$cap" -p MemorySwapMax=0 nice -n 10 "$@"
  else
    nice -n 10 "$@"
  fi
}

if [ -n "$use_cap" ]; then
  if ! command -v systemd-run >/dev/null; then
    echo "check-each: systemd-run is not available, so the memory ceiling cannot be applied." >&2
    echo "            Pass --no-cap to run without it." >&2
    exit 2
  fi
  if ! capped true; then
    echo "check-each: could not start a memory-capped scope (is there a systemd user session?)." >&2
    echo "            Pass --no-cap to run without a ceiling." >&2
    exit 2
  fi
fi

tmp_logs=
if [ -z "$logs" ]; then
  logs=$(mktemp -d "${TMPDIR:-/tmp}/check-each.XXXXXX")
  tmp_logs=1
else
  mkdir -p "$logs"
fi

if [ -z "$system" ]; then
  if ! system=$(capped nix eval --impure --raw --expr builtins.currentSystem 2>"$logs/system.log"); then
    echo "check-each: could not find this machine's system:" >&2
    tail -n 20 "$logs/system.log" >&2
    exit 2
  fi
fi

if ! capped nix eval --json "$flake#checks.$system" --apply builtins.attrNames >"$logs/list.json" 2>"$logs/list.log"; then
  echo "check-each: could not list $flake#checks.$system:" >&2
  tail -n 20 "$logs/list.log" >&2
  exit 2
fi
mapfile -t all < <(jq -r '.[]' "$logs/list.json")

has() { # has NAME LIST...
  local x=$1 y
  shift
  for y in "$@"; do
    if [ "$x" = "$y" ]; then return 0; fi
  done
  return 1
}

for n in "${want[@]}" "${skip[@]}"; do
  if ! has "$n" "${all[@]}"; then
    echo "check-each: no check called $n in $flake#checks.$system (see --list)" >&2
    exit 2
  fi
done
selected=()
for n in "${all[@]}"; do
  if [ "${#want[@]}" -gt 0 ] && ! has "$n" "${want[@]}"; then continue; fi
  if has "$n" "${skip[@]}"; then continue; fi
  selected+=("$n")
done
if [ -n "$list" ]; then
  printf '%s\n' "${selected[@]}"
  exit 0
fi

passed=()
failed=()
killed=()
skip_missing=

# step LABEL COMMAND...: run one command capped, log it, print one line, count it.
step() {
  local label=$1 log start rc=0 took
  shift
  log="$logs/${label//[^A-Za-z0-9._-]/_}.log"
  start=$SECONDS
  capped "$@" >"$log" 2>&1 || rc=$?
  took=$((SECONDS - start))
  case $rc in
    0)
      printf 'ok      %-42s %4ss\n' "$label" "$took"
      passed+=("$label")
      ;;
    137)
      printf 'KILLED  %-42s %4ss  (SIGKILL; at the ceiling (%s) that is out of memory: NOT RUN)\n' "$label" "$took" "$cap_text"
      killed+=("$label")
      ;;
    *)
      if [ -n "$skip_missing" ] && grep -q 'does not provide attribute' "$log"; then
        printf 'skip    %-42s (the flake has none)\n' "$label"
      else
        printf 'FAIL    %-42s %4ss  (exit %s; log %s)\n' "$label" "$took" "$rc" "$log"
        tail -n 30 "$log" | sed 's/^/        | /'
        failed+=("$label")
      fi
      ;;
  esac
}

trap 'echo; echo "check-each: interrupted"; exit 130' INT

echo "check-each: ${#selected[@]} checks of $flake#checks.$system, one at a time, each capped at $cap_text (swap off), --cores $cores; logs in $logs"
for name in "${selected[@]}"; do
  step "$name" nix build "$flake#checks.$system.$name" --no-link --max-jobs 1 --cores "$cores" --print-build-logs
done

if [ -n "$outputs" ] && [ "${#want[@]}" -eq 0 ]; then
  echo
  echo "the flake's other outputs:"
  skip_missing=1
  for o in homeModules nixosModules templates lib; do
    step "output:$o" nix eval --json "$flake#$o" --apply builtins.attrNames
  done
  step "output:packages" nix eval --json "$flake#packages.$system" --apply 'ps: builtins.mapAttrs (_: p: p.drvPath) ps'
  step "output:devShells" nix eval --json "$flake#devShells.$system" --apply 'ps: builtins.mapAttrs (_: p: p.drvPath) ps'
  step "output:apps" nix eval --json "$flake#apps.$system" --apply 'as: builtins.mapAttrs (_: a: a.program) as'
  step "output:formatter" nix eval --raw "$flake#formatter.$system.drvPath"
fi

echo
echo "check-each: ${#passed[@]} passed, ${#failed[@]} failed, ${#killed[@]} not run (killed at the ceiling)"
if [ "${#failed[@]}" -gt 0 ]; then echo "  failed: ${failed[*]}"; fi
if [ "${#killed[@]}" -gt 0 ]; then echo "  not run: ${killed[*]}"; fi

if [ "${#failed[@]}" -gt 0 ]; then
  echo "  logs kept in $logs"
  exit 1
fi
if [ "${#killed[@]}" -gt 0 ]; then
  echo "  logs kept in $logs"
  exit 3
fi
if [ -n "$tmp_logs" ]; then rm -rf "$logs"; fi
exit 0
