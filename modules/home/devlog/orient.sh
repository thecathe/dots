#!/usr/bin/env bash
# orient: tell a session where it is. Run by Claude Code's SessionStart hook, it
# brings the devlog up to date (by calling dlsync), looks at the repository the
# session started in, and prints a short preamble: the repository's devlog
# folder, how finished work is integrated, its dev/workbench branch, the
# repository's own rules (the registry's `notes`, printed as `note:` lines, in
# place of a CLAUDE.md in the repository), and the effort the AI marker assumes. A hook's stdout is the session's context, so what
# it prints is what a session knows without being told.
#
#   orient                    sync, then print the preamble (what you read by hand)
#   orient --hook             the same, shaped for the SessionStart hook: exit 0
#                             whatever happens, and a failure is part of the output
#   orient push-workbench     push dev/workbench to origin, if (and only if) the
#                             repository is yours, private, and the push is a plain
#                             fast-forward of that one branch
#   orient push-workbench --create
#                             the same, creating the branch on origin; this is the
#                             author's explicit yes, so it is not on any allowlist
#
# The facts that cannot be derived live in registry.toml in the devlog (see
# devlog/dots/orient.md). orient stores nothing, runs no daemon and never edits
# the registry or the project. It uses the network for `git fetch` (the devlog by
# dlsync, then dev/workbench) and, to push, for one `gh` check.
#
# Why --hook exists: a SessionStart hook's stdout reaches Claude only when the
# hook exits 0, and the preamble must not vanish just because the devlog could
# not be synced: a clone another session left dirty or mid-merge, a merge
# conflict, or the git host unreachable or refusing (Claude Code needs only the
# Anthropic API, so this can happen with a session running fine). So with
# --hook a failed sync comes out as
# hook JSON, `systemMessage` for the user and the failure in the context for
# Claude, and the exit status stays 0.
#
# Exit codes: 0 done, 10-13 dlsync's (the sync failed; the preamble is still
# printed), 20 push-workbench refused by a rule, 21 push-workbench could not
# establish the repository is private, 22 the fetch or push failed, 64 bad
# usage, 1 anything unforeseen.

registry=${ORIENT_REGISTRY:-${ORIENT_DEFAULT_REGISTRY:-}}
devlog=${ORIENT_DEVLOG_DIR:-${ORIENT_DEFAULT_DEVLOG_DIR:-}}
gh_cmd=${ORIENT_GH:-gh}
workbench=dev/workbench
remote=origin
usage='usage: orient [--hook]
       orient push-workbench [--create]'

cmd=session
hook=0
create=0
while (($#)); do
  case $1 in
    push-workbench) cmd=push ;;
    --hook) hook=1 ;;
    --create) create=1 ;;
    -h | --help)
      echo "$usage"
      exit 0
      ;;
    *)
      printf 'orient: unknown argument: %s\n%s\n' "$1" "$usage" >&2
      exit 64
      ;;
  esac
  shift
done
if ((hook && create)) || { [[ $cmd == push ]] && ((hook)); } || { [[ $cmd == session ]] && ((create)); }; then
  printf 'orient: those options do not go together\n%s\n' "$usage" >&2
  exit 64
fi

# fail CODE HEADLINE [DETAIL...]: the headline is one self-contained line, since
# a hook notice shows only the first line of stderr.
fail() {
  local code=$1 headline=$2
  shift 2
  {
    printf 'orient: FAILED: %s\n' "$headline"
    local detail
    for detail in "$@"; do
      [[ -n $detail ]] && printf '%s\n' "$detail" | sed 's/^/  /'
    done
  } >&2
  exit "$code"
}

# Anything that slips past the explicit checks must not exit silently. (No
# `set -E`, as in dlsync: it would fire inside every $(...) and print twice.)
trap 'fail 1 "unexpected error (exit $?) at line $LINENO: $BASH_COMMAND"' ERR

# Never block on a prompt (a hook has no terminal), never open an editor, and
# keep git's messages in one language so nothing here depends on the locale.
export GIT_TERMINAL_PROMPT=0 GIT_EDITOR=true LC_ALL=C GH_PROMPT_DISABLED=1
# dlsync takes its clone from here, so the devlog has one source of truth.
[[ -z $devlog ]] || export DLSYNC_DIR=${DLSYNC_DIR:-$devlog}

g() { git -C "$top" "$@"; }

# parse_remote URL: set r_host, r_owner, r_name from a remote's URL, whatever
# its form (https, ssh://, scp-like, or a local path). Fails if there are no
# two path components to take an owner and a name from.
parse_remote() {
  local u=${1%/} rest path
  u=${u%.git}
  r_host=''
  case $u in
    *://*)
      rest=${u#*://}
      rest=${rest#*@}
      r_host=${rest%%/*}
      r_host=${r_host%%:*}
      path=${rest#*/}
      ;;
    *@*:*)
      rest=${u#*@}
      r_host=${rest%%:*}
      path=${rest#*:}
      ;;
    *) path=$u ;;
  esac
  path=${path#/}
  r_name=${path##*/}
  [[ $path == */* ]] || return 1
  rest=${path%/*}
  r_owner=${rest##*/}
  [[ -n $r_owner && -n $r_name ]]
}

# find_repo: describe the repository in the working directory (top, id, owner,
# host), or fail if it is not one, or has no origin, or one that has no owner.
find_repo() {
  local url
  top=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  url=$(g config --get "remote.$remote.url" 2>/dev/null) || return 1
  parse_remote "$url" || return 1
  id=$r_owner/$r_name
}

# load_registry: reg is the registry as JSON ({} when it is missing or broken,
# with reg_note saying so), facts is what this repository's entry and the
# defaults say about it.
load_registry() {
  local out
  reg='{}'
  reg_note=''
  if [[ -z $registry ]]; then
    reg_note="no registry configured"
  elif [[ ! -r $registry ]]; then
    reg_note="no registry at $registry"
  elif out=$(python3 -I -c 'import json, sys, tomllib; json.dump(tomllib.load(sys.stdin.buffer), sys.stdout, default=str)' <"$registry" 2>&1); then
    reg=$out
  else
    reg_note="registry.toml does not parse ($(tail -n 1 <<<"$out"))"
  fi
  # A field that is present but false still counts, which jq's `//` would not.
  if ! facts=$(jq -c --arg id "$id" --arg owner "$r_owner" '
    def field($o; $k): if ($o | has($k)) then $o[$k] else null end;
    (.defaults // {}) as $d
    | (((.repos // {})[$id]) // {}) as $r
    | {
        mine: ((($d.owners // []) | index($owner)) != null),
        devlog: field($r; "devlog"),
        branches: ((field($r; "integration_branch") // "main") | if type == "array" then . else [.] end),
        push: (field($r; "push") // false),
        upstream: field($r; "upstream"),
        notes: ((field($r; "notes") // []) | if type == "array" then map(tostring) else [tostring] end),
        effort: ($d.effort // {})
      }' <<<"$reg" 2>&1); then
    reg_note="registry.toml has an unexpected shape ($(tail -n 1 <<<"$facts"))"
    facts=$(jq -cn --arg owner "$r_owner" '{mine: false, devlog: null, branches: ["main"], push: false, upstream: null, notes: [], effort: {}}')
  fi
}
fact() { jq -r "$1" <<<"$facts"; }

# checkout_of BRANCH: the path of the worktree that has BRANCH checked out, if any.
checkout_of() {
  g worktree list --porcelain | awk -v b="refs/heads/$1" '
    $1 == "worktree" { sub(/^worktree /, ""); wt = $0 }
    $1 == "branch" && $2 == b { found = wt }
    END { if (found != "") print found }'
}

declare -a pre=()
add() { pre+=("$*"); }

# --- the preamble ------------------------------------------------------------

# devlog_section: the devlog line; sets has_folder, which the effort line (last,
# whenever the repository has a devlog folder) depends on.
has_folder=0
devlog_section() {
  local folder dir
  # `devlog = false` in the registry says there is no folder (the devlog repo itself).
  if [[ $(fact '.devlog') == false ]]; then return; fi
  folder=$(fact '.devlog // empty')
  folder=${folder:-$r_name}
  dir=$devlog/$folder
  if [[ -n $devlog && -f $dir/index.md ]]; then
    has_folder=1
    add "  devlog: $folder/ - read $dir/index.md first"
  elif [[ $(fact '.mine') == true && -n $devlog ]]; then
    add "  devlog: no folder $folder/ in $devlog yet; ask the author before starting one"
  fi
}

effort_section() {
  ((has_folder)) || return 0
  add "  AI-marker effort: $(fact '.effort | to_entries | map("\(.key)=\(.value)") | join(", ")'); any other model: ask the author, or write \"unrecorded\""
}

integration_section() {
  local branches
  branches=$(fact '.branches | join(" and ")')
  if [[ $(fact '.push') == true ]]; then
    add "  integration: $branches; local git merge --no-ff (never squash), then push it to $remote; no PR"
  elif [[ $(fact '.mine') == true ]]; then
    add "  integration: $branches; local git merge --no-ff (never squash); no push or PR unless asked"
  else
    add "  integration: not yours ($r_owner): finished work goes by a pull request on the remote; do not push to it"
  fi
  local upstream
  upstream=$(fact '.upstream // empty')
  [[ -z $upstream ]] ||
    add "  upstream: $upstream (only where a PR would go; work here does not touch it unless the author says so)"
  # With several long-lived branches, a topic must not make merging them later
  # conflict: it starts from their merge base and goes into each. This used to be
  # said by the repository's own CLAUDE.md.
  if (($(fact '.branches | length') > 1)); then
    add "  several integration branches: start a topic branch from \`git merge-base\` of them and merge that same branch into each, so merging one into another later does not conflict"
  fi
}

# notes_section: the repository's own rules, as the registry words them, one line
# each (a note is a sentence for a session, not a fact orient can check). They are
# what a project's CLAUDE.md used to carry.
notes_section() {
  local n
  while IFS= read -r n; do
    [[ -z $n ]] || add "  note: $n"
  done < <(fact '.notes[] | gsub("\\s+"; " ") | sub("^ "; "") | sub(" $"; "")')
}

# workbench_section: fetch dev/workbench, fast-forward the local branch when only
# origin moved, and say where it stands. Never merges, never pushes, never
# touches a checkout with uncommitted changes.
workbench_section() {
  local lref=refs/heads/$workbench rref=refs/remotes/$remote/$workbench
  local have_l=0 have_r=0 ferr='' fnote='' ahead=0 behind=0 checkout state readme_ref
  if ! ferr=$(timeout 15 git -C "$top" fetch --quiet --no-tags "$remote" "+$lref:$rref" 2>&1); then
    if [[ $ferr == *"couldn't find remote ref"* ]]; then
      # Gone from the remote (or never there): drop a stale tracking ref, as --prune would.
      g update-ref -d "$rref" 2>/dev/null || true
    else
      fnote="could not fetch $remote ($(head -n 1 <<<"$ferr")); this is the state as of the last fetch"
    fi
  fi
  g rev-parse --verify -q "$lref" >/dev/null && have_l=1
  g rev-parse --verify -q "$rref" >/dev/null && have_r=1
  ((have_l || have_r)) || return 0

  if ((have_l && have_r)); then
    read -r ahead behind <<<"$(g rev-list --left-right --count "$lref...$rref")"
    if ((ahead == 0 && behind == 0)); then
      state="level with $remote"
    elif ((ahead == 0)); then
      checkout=$(checkout_of "$workbench")
      if [[ -n $checkout ]]; then
        if [[ -n $(git -C "$checkout" status --porcelain --untracked-files=no) ]]; then
          state="$behind commit(s) behind $remote; not updated, its checkout $checkout has uncommitted changes"
        elif git -C "$checkout" merge --ff-only --quiet "$rref" >/dev/null 2>&1; then
          state="fast-forwarded $behind commit(s) from $remote"
        else
          state="$behind commit(s) behind $remote; the fast-forward in $checkout failed"
        fi
      elif g update-ref -m "orient: fast-forward $workbench from $remote" "$lref" "$rref" "$(g rev-parse "$lref")" 2>/dev/null; then
        state="fast-forwarded $behind commit(s) from $remote"
      else
        state="$behind commit(s) behind $remote; could not update the branch"
      fi
    elif ((behind == 0)); then
      state="$ahead commit(s) ahead of $remote (publish them with: orient push-workbench)"
    else
      state="diverged from $remote ($ahead ahead, $behind behind); left alone, tell the author"
    fi
  elif ((have_l)); then
    state="local only, not on $remote"
  else
    state="on $remote only; no local branch in this clone"
  fi

  readme_ref=$workbench
  ((!have_r)) || readme_ref=$remote/$workbench
  if g cat-file -e "$readme_ref:dev/README.md" 2>/dev/null; then
    add "  workbench: $workbench, $state; README: git show $readme_ref:dev/README.md"
  else
    add "  workbench: $workbench, $state; no dev/README.md on it yet"
  fi
  [[ -z $fnote ]] || add "  workbench: $fnote"
}

# --- push-workbench ----------------------------------------------------------

push_workbench() {
  local lref=refs/heads/$workbench rref=refs/remotes/$remote/$workbench ferr private ahead behind out
  find_repo || fail 20 "not in a git repository with an $remote that names an owner and a name"
  load_registry
  [[ $(fact '.mine') == true ]] ||
    fail 20 "$id is not yours (its owner is not in the registry's owners); the workbench is not pushed" \
      "Ask the author, or put the owner in defaults.owners in $registry."
  [[ $r_host == github.com ]] ||
    fail 20 "$remote of $id is not on github.com (host: ${r_host:-none}); visibility cannot be checked" \
      "Ask the author before pushing the workbench anywhere else."
  g rev-parse --verify -q "$lref" >/dev/null || fail 20 "there is no local $workbench in $id; nothing to push"

  # The registry's word would only be a hint: a repository can go public later.
  if ! out=$(timeout 30 "$gh_cmd" repo view "$id" --json isPrivate --jq .isPrivate 2>&1); then
    fail 21 "could not check whether $id is private, so it is treated as public" "$out" \
      "Ask the author; a session must not push the workbench on a guess."
  fi
  private=$out
  [[ $private == true ]] || fail 20 "$id is not private (gh says: $private); the workbench stays local" \
    "A public repository's workbench is not pushed without a decision from the author."

  if ! ferr=$(timeout 30 git -C "$top" fetch --quiet --no-tags "$remote" "+$lref:$rref" 2>&1); then
    if [[ $ferr == *"couldn't find remote ref"* ]]; then
      g update-ref -d "$rref" 2>/dev/null || true
    else
      fail 22 "could not fetch $remote" "$ferr"
    fi
  fi

  if g rev-parse --verify -q "$rref" >/dev/null; then
    read -r ahead behind <<<"$(g rev-list --left-right --count "$lref...$rref")"
    ((behind == 0)) ||
      fail 20 "$workbench is not a fast-forward of $remote/$workbench ($ahead ahead, $behind behind); nothing was pushed" \
        "Fast-forward it first, or tell the author. This command never forces."
    if ((ahead == 0)); then
      echo "orient: $workbench is level with $remote/$workbench; nothing to push"
      return 0
    fi
  else
    ((create)) ||
      fail 20 "$remote has no $workbench; creating it needs the author's explicit yes" \
        "Once they have said yes: orient push-workbench --create"
    # Only what origin does not already have (main's history is there).
    ahead=$(g rev-list --count "$lref" --not --remotes="$remote")
  fi

  # An explicit refspec and no --force: the one ref, fast-forward only.
  if ! out=$(timeout 60 git -C "$top" push --quiet "$remote" "$lref:refs/heads/$workbench" 2>&1); then
    fail 22 "pushing $workbench to $remote failed" "$out"
  fi
  echo "orient: pushed $ahead commit(s) of $workbench to $remote/$workbench"
}

if [[ $cmd == push ]]; then
  push_workbench
  exit 0
fi

# --- the session start -------------------------------------------------------

errfile=$(mktemp)
trap 'rm -f "$errfile"' EXIT

sync_args=()
((!hook)) || sync_args+=(--quiet)
sync_out=$(dlsync "${sync_args[@]}" 2>"$errfile") && sync_code=0 || sync_code=$?
sync_err=$(<"$errfile")
sync_headline=''
if ((sync_code != 0)); then
  sync_headline=$(head -n 1 <<<"$sync_err")
  sync_headline=${sync_headline#dlsync: FAILED: }
  sync_headline=${sync_headline:-dlsync exited $sync_code}
fi

if find_repo; then
  load_registry
  add "orient: $id ($([[ $(fact '.mine') == true ]] && echo yours || echo "not yours"))"
  # No entry is the normal case (the registry holds only exceptions), so it is
  # not worth a line; a registry that is missing or broken is.
  [[ -z $reg_note ]] || add "  registry: $reg_note"
  devlog_section
  integration_section
  workbench_section
  notes_section
  effort_section
fi

if ((sync_code != 0)); then
  add "orient: the devlog is NOT in step with its origin: $sync_headline"
  add "  The clone is as it was. Tell the author at the start of your first reply; the details are in dlsync's own message."
fi

# What a person running it by hand sees first: dlsync's progress lines.
if ((!hook)); then
  [[ -z $sync_out ]] || printf '%s\n' "$sync_out"
fi

if ((hook)); then
  if ((${#pre[@]} > 0)); then
    context=$(printf '%s\n' "${pre[@]}")
    if ((sync_code != 0)); then
      # Exit 0 keeps the context; systemMessage is the user's notice.
      jq -n --arg msg "orient: devlog sync failed: $sync_headline" --arg ctx "$context" \
        '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
    else
      printf '%s\n' "$context"
    fi
  fi
  exit 0
fi

((${#pre[@]} == 0)) || printf '%s\n' "${pre[@]}"
if ((sync_code != 0)); then
  printf 'orient: FAILED: %s\n' "$sync_headline" >&2
  [[ -z $sync_err ]] || printf '%s\n' "$sync_err" | tail -n +2 >&2
  exit "$sync_code"
fi
