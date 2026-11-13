#!/usr/bin/env bash
# Behaviour of dlsync against real repositories: a bare origin and two clones
# standing in for the two hosts. Run by checks/dlsync.nix (dlsync, git and
# util-linux on PATH); run by hand the same way.
set -u

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
export HOME=$root/home GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
git config --global user.name tester
git config --global user.email tester@example.invalid
git config --global init.defaultBranch main
git config --global core.editor false # an editor opening anywhere is a failure

fails=0
ok() { printf 'ok    %s\n' "$1"; }
bad() {
  printf 'FAIL  %s\n' "$1"
  fails=$((fails + 1))
}
check() { # check NAME CONDITION-COMMAND...
  local name=$1
  shift
  if "$@"; then ok "$name"; else bad "$name"; fi
}
contains() { [[ $1 == *"$2"* ]]; }

# run [dlsync args...] in clone $dir: sets code, out (stdout), err (stderr)
run() {
  local o e
  o=$(mktemp -p "$root")
  e=$(mktemp -p "$root")
  dlsync --dir "$dir" "$@" >"$o" 2>"$e"
  code=$?
  out=$(<"$o")
  err=$(<"$e")
}
# The other host: always up to date before it writes, as a real one would be.
a_sync() { git -C "$A" pull -q --no-rebase --no-edit; }
head_of() { git -C "$1" rev-parse HEAD; }
commit() { # commit CLONE FILE CONTENT MESSAGE
  printf '%s\n' "$3" >"$1/$2"
  git -C "$1" add "$2"
  git -C "$1" commit -q -m "$4"
}

origin=$root/origin.git
git init -q --bare "$origin"
seed=$root/seed
git init -q "$seed"
{ for i in $(seq 1 20); do echo "line $i"; done; } >"$seed/index.md"
git -C "$seed" add index.md
git -C "$seed" commit -q -m "docs: seed"
git -C "$seed" push -q "$origin" main
git clone -q "$origin" "$root/nixos"
git clone -q "$origin" "$root/worklaptop"
A=$root/nixos
B=$root/worklaptop
host=$(uname -n)

dir=$B
run
check "up to date: exit 0" test "$code" = 0
check "up to date: says so" contains "$out" "up to date"

a_sync
commit "$A" a1.md "from nixos" "docs(dots): a1"
git -C "$A" push -q origin main
run
check "behind only: exit 0" test "$code" = 0
check "behind only: fast-forwarded" contains "$out" "fast-forwarded 1 commit"
check "behind only: file arrived" test -f "$B/a1.md"
check "behind only: no merge commit" test "$(git -C "$B" rev-list --merges --count HEAD)" = 0

commit "$B" b1.md "from worklaptop" "docs(dots): b1"
before=$(git -C "$origin" rev-parse main)
run
check "ahead only: exit 0, no push by default" test "$code" = 0 -a "$(git -C "$origin" rev-parse main)" = "$before"
check "ahead only: says what is unpushed" contains "$out" "1 local commit(s) not yet on origin/main"
run --push
check "ahead + --push: exit 0" test "$code" = 0
check "ahead + --push: origin has it" test "$(git -C "$origin" rev-parse main)" = "$(head_of "$B")"
run --push
check "--push with nothing to push" contains "$out" "nothing to push"

# Diverged, no overlap: one sync merge in the house format, then pushable.
a_sync
commit "$A" a2.md "from nixos" "docs(dots): a2"
git -C "$A" push -q origin main
commit "$B" b2.md "from worklaptop" "docs(dots): b2"
run --push
check "diverged: exit 0" test "$code" = 0
check "diverged: sync merge subject" test "$(git -C "$B" log -1 --format=%s)" = "chore(sync): merge origin/main into main on $host"
check "diverged: it is a two-parent merge" test "$(git -C "$B" rev-list --parents -1 HEAD | wc -w)" = 3
check "diverged: both sides' files present" test -f "$B/a2.md" -a -f "$B/b2.md"
check "diverged: pushed" test "$(git -C "$origin" rev-parse main)" = "$(head_of "$B")"
check "diverged: no editor, no leftovers" test -z "$(git -C "$B" status --porcelain)"
git -C "$A" pull -q --ff-only

# Same file on both sides, different places: merges cleanly, but says so.
a_sync
sed -i '1s/.*/line 1 (nixos)/' "$A/index.md"
git -C "$A" commit -q -am "docs: edit top"
git -C "$A" push -q origin main
sed -i '20s/.*/line 20 (worklaptop)/' "$B/index.md"
git -C "$B" commit -q -am "docs: edit bottom"
run
check "same file, apart: exit 0" test "$code" = 0
check "same file, apart: both edits kept" test "$(sed -n '1p;20p' "$B/index.md" | tr '\n' '|')" = "line 1 (nixos)|line 20 (worklaptop)|"
check "same file, apart: flagged for a read" contains "$out" "both sides changed these files"
check "same file, apart: names index.md" contains "$out" "index.md"
git -C "$B" push -q origin main
git -C "$A" pull -q --ff-only

# A real conflict: loud, first line self-contained, clone untouched.
a_sync
sed -i '10s/.*/line 10 (nixos)/' "$A/index.md"
git -C "$A" commit -q -am "docs: nixos line 10"
git -C "$A" push -q origin main
sed -i '10s/.*/line 10 (worklaptop)/' "$B/index.md"
git -C "$B" commit -q -am "docs: worklaptop line 10"
mine=$(head_of "$B")
run --push
check "conflict: exit 11" test "$code" = 11
check "conflict: headline is the first stderr line" contains "$(head -n1 <<<"$err")" "dlsync: FAILED: merging origin/main conflicts"
check "conflict: names the file" contains "$err" "index.md"
check "conflict: nothing on stdout" test -z "$out"
check "conflict: HEAD unchanged" test "$(head_of "$B")" = "$mine"
check "conflict: merge aborted, tree clean" test -z "$(git -C "$B" status --porcelain)" -a ! -e "$B/.git/MERGE_HEAD"
check "conflict: nothing pushed" test "$(git -C "$origin" rev-parse main)" != "$mine"
run --quiet
check "conflict: --quiet still fails loudly" test "$code" = 11 -a -n "$err"
git -C "$B" reset -q --hard origin/main # leave the clone in sync for what follows

# Preconditions.
echo scribble >>"$B/index.md"
run
check "dirty tree: exit 10" test "$code" = 10
check "dirty tree: says why" contains "$(head -n1 <<<"$err")" "uncommitted changes"
git -C "$B" checkout -q -- index.md

git -C "$B" checkout -q -b scratch
run
check "wrong branch: exit 10" test "$code" = 10
check "wrong branch: names it" contains "$(head -n1 <<<"$err")" "'scratch', not main"
git -C "$B" checkout -q main

git -C "$B" branch -q -D scratch

head_of "$B" >"$B/.git/REVERT_HEAD" # an operation left in progress
run
check "operation in progress: exit 10" test "$code" = 10
check "operation in progress: names it" contains "$(head -n1 <<<"$err")" "already in progress (REVERT_HEAD)"
rm -f "$B/.git/REVERT_HEAD"

run --nonsense
check "bad usage: exit 64" test "$code" = 64

# Quiet means silent on success, because a hook's stdout is Claude's context.
a_sync
commit "$A" a3.md "from nixos" "docs(dots): a3"
git -C "$A" push -q origin main
run --quiet
check "--quiet success: exit 0 and no output at all" test "$code" = 0 -a -z "$out" -a -z "$err"
check "--quiet success: still synced" test -f "$B/a3.md"

# Network and push failures.
git -C "$B" remote set-url origin "$root/does-not-exist.git"
run
check "fetch failure: exit 13" test "$code" = 13
check "fetch failure: says so" contains "$(head -n1 <<<"$err")" "could not fetch origin"
git -C "$B" remote set-url origin "$origin"

commit "$B" b3.md "from worklaptop" "docs(dots): b3"
printf '#!/bin/sh\necho "rejected by test hook" >&2\nexit 1\n' >"$origin/hooks/pre-receive"
chmod +x "$origin/hooks/pre-receive"
run --push
check "push rejected: exit 12" test "$code" = 12
check "push rejected: headline" contains "$(head -n1 <<<"$err")" "pushing main to origin failed"
check "push rejected: remote's reason shown" contains "$err" "rejected by test hook"
rm -f "$origin/hooks/pre-receive"
run --push
check "push after the cause is gone: exit 0" test "$code" = 0

# Two at once: the second waits for the first, then finds nothing to do.
exec 8>"$B/.git/dlsync.lock"
flock -n 8
DLSYNC_LOCK_WAIT=1 run
check "lock held elsewhere: exit 10" test "$code" = 10
check "lock held elsewhere: says so" contains "$(head -n1 <<<"$err")" "another dlsync"
exec 8>&-

printf '\n%s failure(s)\n' "$fails"
exit $((fails > 0))
