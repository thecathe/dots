#!/usr/bin/env bash
# check: evaluate every machine of a flake that consumes dots, optionally against
# another dots than the one it has locked. Run it before merging a dots change: dots
# cannot see its consumers, and this is what tells it whether it would break one.
# Until 2026-11-21 this was `./check` in the hosts repository.
#
#   check [OPTIONS] [DOTS]
#
#   DOTS          the dots to evaluate against: a path to a git checkout or worktree
#                 (read at a snapshot commit of its tracked files, uncommitted edits
#                 included; new files need `git add`), or any flake ref. Omitted: the
#                 dots the flake has locked. Nothing is locked or written either way.
#   --flake DIR   the consumer flake (default: the current directory)
#   --input NAME  the consumer's input that is dots (default: dots)
#   --only NAME   only this machine (repeatable); NAME as printed
#   --baseline    also evaluate against the locked dots, and say which machines
#                 changed (needs DOTS); exits 2 if any did and nothing failed
#   --diff        with --baseline: for a machine that changed, list the derivations
#                 that differ, by name (changed, added, removed)
#   --build       also build each machine (slow; BUILD=1 in the environment too)
#   -q, --quiet   leave out the evaluation warnings
#
# The machines are every nixosConfigurations (its system.build.toplevel) and every
# homeConfigurations (its activationPackage) of the flake. Prints each one's
# derivation path: identical paths before and after prove a refactor changed nothing.
# A machine that fails to evaluate gets nix's own error output; one that evaluates
# gets its warnings (once each). Exits 1 if any machine fails.
set -u

usage() { sed -n '/^#   check/,/^# derivation path/p' "$0" | sed 's/^# \{0,1\}//' >&2; }

flake=.
input=dots
dots=
baseline=
diff=
build=${BUILD:-}
warn=1
only=()
while (($#)); do
  case $1 in
    --flake) flake=${2:?--flake needs a directory}; shift 2 ;;
    --input) input=${2:?--input needs a name}; shift 2 ;;
    --only) only+=("${2:?--only needs a name}"); shift 2 ;;
    --baseline) baseline=1; shift ;;
    --diff) diff=1; shift ;;
    --build) build=1; shift ;;
    -q | --quiet) warn=; shift ;;
    -h | --help) usage; exit 0 ;;
    -*) echo "check: unknown option $1" >&2; usage; exit 2 ;;
    *)
      if [ -n "$dots" ]; then echo "check: only one DOTS argument" >&2; exit 2; fi
      dots=$1; shift ;;
  esac
done
if [ -n "$baseline" ] && [ -z "$dots" ]; then
  echo "check: --baseline compares against DOTS, so it needs one" >&2
  exit 2
fi
if [ -n "$diff" ] && [ -z "$baseline" ]; then
  echo "check: --diff needs --baseline" >&2
  exit 2
fi
if [ -d "$flake" ]; then flake=$(realpath "$flake"); fi

base=(--no-write-lock-file)
override=("${base[@]}")
if [ -n "$dots" ]; then
  ref=$dots
  if [ -d "$ref" ]; then
    # A checkout is read at a snapshot commit of its tracked files, never as a
    # working tree: dots' settings.json clean filter would otherwise let nix cache
    # local content under a public commit's hash (see modules/home/rebuild).
    ref=$(dots-snapshot "$ref") || exit 1
  fi
  override+=(--override-input "$input" "$ref")
fi

errors=$(mktemp)
trap 'rm -f "$errors"' EXIT

# The names under one output attribute, one per line; none if the flake has no
# such attribute. Any other failure is reported and ends the run.
names() {
  local out
  if out=$(nix eval --raw "${override[@]}" "$flake#$1" \
    --apply 'xs: builtins.concatStringsSep "\n" (builtins.attrNames xs)' 2>"$errors"); then
    [ -z "$out" ] || printf '%s\n' "$out"
  elif grep -q "does not provide attribute" "$errors"; then
    :
  else
    echo "check: cannot list $1 of $flake:" >&2
    cat "$errors" >&2
    exit 1
  fi
}

# name<TAB>attribute, for every machine. (Listed first, not in a process
# substitution, so that a failure to list ends the run.)
nixos_names=$(names nixosConfigurations) || exit 1
home_names=$(names homeConfigurations) || exit 1
machines=()
while IFS= read -r n; do
  [ -z "$n" ] || machines+=("$n"$'\t'"nixosConfigurations.\"$n\".config.system.build.toplevel")
done <<<"$nixos_names"
while IFS= read -r n; do
  [ -z "$n" ] || machines+=("$n"$'\t'"homeConfigurations.\"$n\".activationPackage")
done <<<"$home_names"
if ((${#machines[@]} == 0)); then
  echo "check: $flake has no nixosConfigurations or homeConfigurations" >&2
  exit 1
fi

selected() {
  ((${#only[@]} == 0)) && return 0
  local o
  for o in "${only[@]}"; do [ "$o" = "$1" ] && return 0; done
  return 1
}

# Evaluates one attribute's drvPath with the given arguments; prints the path, or
# nix's error output (on stderr) and fails. With WARN=1, also prints the
# evaluation's warnings, once each (nix repeats them per module system), leaving
# out nix's own notes about dirty trees and unwritten lock files.
evaluate() {
  local attr=$1
  shift
  local drv
  if drv=$(nix eval --raw "$@" "$flake#$attr.drvPath" 2>"$errors"); then
    if [ -n "${WARN:-}" ]; then
      { grep -E '^(evaluation )?warning:' "$errors" || true; } |
        { grep -vE "is dirty$|not writing modified lock file" || true; } |
        awk '!seen[$0]++ { print "    " $0 }' >&2
    fi
    printf '%s\n' "$drv"
  else
    sed 's/^/    /' "$errors" >&2
    return 1
  fi
}

# The derivations that differ between two closures, by name: a name with a
# derivation only in the old closure and one only in the new one has changed.
closure_diff() {
  local old=$1 new=$2 o n
  o=$(nix-store -qR "$old" | sort)
  n=$(nix-store -qR "$new" | sort)
  local only_old only_new
  only_old=$(comm -23 <(printf '%s\n' "$o") <(printf '%s\n' "$n") | sed 's|^/nix/store/[a-z0-9]*-||' | sort -u)
  only_new=$(comm -13 <(printf '%s\n' "$o") <(printf '%s\n' "$n") | sed 's|^/nix/store/[a-z0-9]*-||' | sort -u)
  comm -12 <(printf '%s\n' "$only_old") <(printf '%s\n' "$only_new") | sed '/^$/d; s/^/    changed  /'
  comm -13 <(printf '%s\n' "$only_old") <(printf '%s\n' "$only_new") | sed '/^$/d; s/^/    added    /'
  comm -23 <(printf '%s\n' "$only_old") <(printf '%s\n' "$only_new") | sed '/^$/d; s/^/    removed  /'
}

width=0
for m in "${machines[@]}"; do
  n=${m%%$'\t'*}
  if ((${#n} > width)); then width=${#n}; fi
done

failed=0
changed=0
seen=
for m in "${machines[@]}"; do
  name=${m%%$'\t'*}
  attr=${m#*$'\t'}
  selected "$name" || continue
  seen=1
  if ! drv=$(WARN=$warn evaluate "$attr" "${override[@]}"); then
    printf '%-*s  EVALUATION FAILED (rerun: nix eval %s %s#%s.drvPath)\n' "$width" "$name" "${override[*]}" "$flake" "$attr" >&2
    failed=1
    continue
  fi
  if [ -n "$baseline" ]; then
    if ! old=$(evaluate "$attr" "${base[@]}"); then
      printf '%-*s  %s (the locked dots FAILED to evaluate)\n' "$width" "$name" "$drv" >&2
      failed=1
    elif [ "$old" = "$drv" ]; then
      printf '%-*s  same     %s\n' "$width" "$name" "$drv"
    else
      printf '%-*s  CHANGED  %s (was %s)\n' "$width" "$name" "$drv" "$old"
      changed=1
      [ -z "$diff" ] || closure_diff "$old" "$drv"
    fi
  else
    printf '%-*s  %s\n' "$width" "$name" "$drv"
  fi
  if [ -n "$build" ] && ! nix build --no-link "${override[@]}" "$flake#$attr" 2>&1 | tail -3; then
    echo "$name: BUILD FAILED" >&2
    failed=1
  fi
done
if ((${#only[@]} > 0)) && [ -z "$seen" ]; then
  echo "check: no machine named ${only[*]}" >&2
  exit 2
fi
if ((failed)); then exit 1; fi
if ((changed)); then exit 2; fi
exit 0
