#!/usr/bin/env bash
# dlsync: bring this host's devlog clone in line with origin, and optionally
# publish it. Written for two hosts that both write to the same devlog: their
# `main`s diverge, and the fix is always the same merge.
#
#   dlsync            fetch origin; fast-forward, or merge when both sides moved
#   dlsync --push     ... then push main to origin (the only thing that pushes)
#   dlsync --quiet    print nothing when it works (for hooks: a hook's stdout
#                     becomes Claude's context, so success must be silent)
#   dlsync --dir DIR  use this clone instead of the configured one
#
# It never rewrites history, never stashes, never resolves a conflict. Anything
# it cannot do by itself it stops on with a non-zero exit and a message on
# stderr, and leaves the clone exactly as it found it (a conflicted merge is
# aborted, not left half-done). The first stderr line is the whole story: Claude
# Code's hook notice shows only that line.
#
# Exit codes: 0 done, 10 the clone is not in a state to sync (wrong branch,
# uncommitted changes, an operation in progress, another dlsync running),
# 11 a merge conflict or other merge failure, 12 the push failed, 13 the fetch
# failed, 64 bad usage, 1 anything unforeseen.

branch=${DLSYNC_BRANCH:-main}
remote=origin
dir=${DLSYNC_DIR:-${DLSYNC_DEFAULT_DIR:-}}
push=0
quiet=0

while (($#)); do
  case $1 in
    --push) push=1 ;;
    --quiet | -q) quiet=1 ;;
    --dir)
      [[ $# -ge 2 ]] || {
        echo "dlsync: --dir needs a path" >&2
        exit 64
      }
      dir=$2
      shift
      ;;
    -h | --help)
      echo "usage: dlsync [--push] [--quiet] [--dir DIR]"
      exit 0
      ;;
    *)
      echo "dlsync: unknown argument: $1 (usage: dlsync [--push] [--quiet] [--dir DIR])" >&2
      exit 64
      ;;
  esac
  shift
done

say() { ((quiet)) || printf 'dlsync: %s\n' "$*"; }

# fail CODE HEADLINE [DETAIL...]: the headline is one self-contained line.
fail() {
  local code=$1 headline=$2
  shift 2
  {
    printf 'dlsync: FAILED: %s\n' "$headline"
    local detail
    for detail in "$@"; do
      [[ -n $detail ]] && printf '%s\n' "$detail" | sed 's/^/  /'
    done
    printf '  clone: %s\n' "$dir"
  } >&2
  exit "$code"
}

# Anything that slips past the explicit checks must not exit silently. (No
# `set -E`: with it the trap would also fire inside every $(...) and print twice.)
trap 'fail 1 "unexpected error (exit $?) at line $LINENO: $BASH_COMMAND"' ERR

# Never block on a prompt (a hook has no terminal), never open an editor, and
# keep git's messages in one language so nothing here depends on the locale.
export GIT_TERMINAL_PROMPT=0 GIT_EDITOR=true GIT_MERGE_AUTOEDIT=no LC_ALL=C

[[ -n $dir ]] || fail 10 "no devlog clone configured" "Set dots.devlog.dir, or pass --dir."
[[ -d $dir ]] || fail 10 "not a directory: $dir"
g() { git -C "$dir" "$@"; }
g rev-parse --git-dir >/dev/null 2>&1 || fail 10 "not a git repository: $dir"

gitdir=$(g rev-parse --absolute-git-dir)
host=$(uname -n)

# Two hooks firing at once (two sessions starting together) take turns: the
# second finds the first's work done and has nothing left to do.
exec 9>"$gitdir/dlsync.lock"
lock_wait=${DLSYNC_LOCK_WAIT:-20}
flock -w "$lock_wait" 9 || fail 10 "another dlsync has held the lock for ${lock_wait} s"

current=$(g symbolic-ref --short -q HEAD || true)
[[ $current == "$branch" ]] ||
  fail 10 "the clone is on '${current:-a detached HEAD}', not $branch" \
    "dlsync only syncs $branch. Put the clone back on $branch, then rerun."

for state in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply; do
  [[ ! -e $gitdir/$state ]] ||
    fail 10 "a git operation is already in progress ($state)" \
      "Finish or abort it (git status shows how), then rerun."
done

dirty=$(g status --porcelain --untracked-files=no)
[[ -z $dirty ]] ||
  fail 10 "uncommitted changes in the clone; dlsync will not merge over them" "$dirty" \
    "Commit or discard them, then rerun."

if ! out=$(timeout 30 git -C "$dir" fetch --quiet "$remote" "$branch" 2>&1); then
  fail 13 "could not fetch $remote (offline, or the remote refused)" "$out"
fi
upstream=$remote/$branch
g rev-parse --verify -q "refs/remotes/$upstream" >/dev/null ||
  fail 13 "$upstream does not exist after fetching"

# ahead: commits only here; behind: commits only on the remote.
read -r ahead behind <<<"$(g rev-list --left-right --count "$branch...$upstream")"

if ((behind == 0)); then
  if ((ahead == 0)); then
    say "up to date with $upstream"
  else
    say "$ahead local commit(s) not yet on $upstream; nothing to pull"
  fi
elif ((ahead == 0)); then
  g merge --ff-only --quiet "$upstream" >/dev/null ||
    fail 11 "could not fast-forward to $upstream"
  say "fast-forwarded $behind commit(s) from $upstream"
else
  # Both sides moved. Note the files each side changed, so a clean merge of
  # a file both of them touched can still be read over afterwards.
  base=$(g merge-base "$branch" "$upstream")
  both=$(comm -12 <(g diff --name-only "$base" "$branch" | sort) <(g diff --name-only "$base" "$upstream" | sort))
  msg="chore(sync): merge $upstream into $branch on $host"
  if ! out=$(g merge --no-ff --no-edit -m "$msg" "$upstream" 2>&1); then
    conflicts=$(g diff --name-only --diff-filter=U || true)
    if [[ -e $gitdir/MERGE_HEAD ]]; then
      g merge --abort ||
        fail 11 "merging $upstream conflicts AND the abort failed: the clone is mid-merge" "$conflicts" \
          "Run 'git merge --abort' in the clone, or resolve it by hand."
    fi
    fail 11 "merging $upstream conflicts; the clone is unchanged" \
      "conflicting files: $(tr '\n' ' ' <<<"$conflicts")" "$out" \
      "Resolve it by hand: git merge $upstream, fix the files, commit, then rerun."
  fi
  say "merged $behind remote commit(s) into $ahead local ($(g rev-parse --short HEAD))"
  [[ -z $both ]] || say "both sides changed these files (git merged them cleanly; worth a read): $(tr '\n' ' ' <<<"$both")"
fi

if ((push)); then
  unpushed=$(g rev-list --count "$upstream..$branch")
  if ((unpushed == 0)); then
    say "nothing to push"
  else
    if ! out=$(timeout 60 git -C "$dir" push --quiet "$remote" "$branch" 2>&1); then
      fail 12 "pushing $branch to $remote failed" "$out" \
        "If the remote moved in the meantime, run dlsync --push again."
    fi
    say "pushed $unpushed commit(s) to $upstream"
  fi
fi
