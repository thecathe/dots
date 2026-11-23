#!/usr/bin/env bash
# Behaviour of repos against real repositories under a throwaway root: a
# repository with a bare origin, merged and unmerged branches, a dirty tree
# and a linked worktree; one with no remote, detached; one on master; a linked
# worktree at the top level (skipped as a repository); an excluded one; and,
# near the end, a clean filter's size-only change and `pull` against one
# origin with clones in each state it reports. Run by
# checks/repos.nix (repos, git and jq on PATH); run by hand the same way.
set -u

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
export HOME=$root/home GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
git config --global user.name tester
git config --global user.email tester@example.invalid
git config --global init.defaultBranch main
git config --global core.editor false

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
not() { ! "$@"; }
# field ID JQ-EXPR: that field of the repository ID in the last status
field() { jq -r --arg id "$1" ".repos[] | select(.id == \$id) | $2" <<<"$json"; }
is() { [ "$(field "$1" "$2")" = "$3" ]; }
# listed ID: whether the last status lists the repository
listed() { jq -e --arg id "$1" '.repos[] | select(.id == $id)' <<<"$json" >/dev/null; }
json_ok() { jq -e . <<<"$json" >/dev/null; }
commit() { # commit DIR FILE CONTENT MESSAGE
  printf '%s\n' "$3" >"$1/$2"
  git -C "$1" add "$2"
  git -C "$1" commit -q -m "$4"
}

g=$root/git
export REPOS_ROOT=$g
export REPOS_INTEGRATION='{"o/legacy":"master"}'
export REPOS_EXCLUDE='["o/skip"]'
unset REPOS_CONFIG

# o/a: origin, branches, dirty, a worktree at the top level.
origin=$root/a.git
git init -q --bare "$origin"
mkdir -p "$g/o"
git clone -q "$origin" "$g/o/a" 2>/dev/null
A=$g/o/a
commit "$A" README "one" "docs: one"
git -C "$A" push -q origin main
git -C "$A" switch -q -c chore/done
commit "$A" done "x" "chore: done"
git -C "$A" switch -q main
git -C "$A" merge -q --no-ff -m "Merge branch 'chore/done'" chore/done
git -C "$A" switch -q -c feat/wip
commit "$A" wip "y" "feat: wip 1"
commit "$A" wip2 "z" "feat: wip 2"
git -C "$A" push -q -u origin feat/wip 2>/dev/null
git -C "$A" push -q origin --delete feat/wip 2>/dev/null # its upstream is now gone
git -C "$A" fetch -q --prune
git -C "$A" switch -q main
git -C "$A" worktree add -q "$g/o/a-wt" -b feat/other
echo dirty >"$A/README"
echo untracked >"$g/o/a-wt/new"

# o/b: no remote, detached HEAD.
git init -q "$g/o/b"
commit "$g/o/b" f "1" "one"
commit "$g/o/b" f "2" "two"
git -C "$g/o/b" checkout -q HEAD~1

# o/legacy: master, named by the integration map.
git init -q -b master "$g/o/legacy"
commit "$g/o/legacy" f "1" "one"
git -C "$g/o/legacy" switch -q -c topic
commit "$g/o/legacy" t "1" "topic"
git -C "$g/o/legacy" switch -q master

# o/skip: excluded. o/notgit: no .git at all.
git init -q "$g/o/skip"
mkdir -p "$g/o/notgit"

json=$(repos --json)
check "status is JSON" json_ok
check "root reported" [ "$(jq -r .root <<<"$json")" = "$g" ]
check "three repositories, sorted" [ "$(jq -r '.repos | map(.id) | join(",")' <<<"$json")" = "o/a,o/b,o/legacy" ]
check "the top-level worktree is not a repository" not listed o/a-wt
check "excluded one left out" not listed o/skip

check "a: branch main" is o/a .branch main
check "a: upstream" is o/a .upstream origin/main
check "a: ahead 2 (merge + chore)" is o/a .ahead 2
check "a: behind 0" is o/a .behind 0
check "a: one changed path" is o/a .dirty 1
check "a: no operation" is o/a .operation null
check "a: fetched set" [ "$(field o/a .fetched)" != null ]
check "a: integration main" is o/a .integration main
check "a: chore/done merged" is o/a '.branches[] | select(.name == "chore/done") | .merged' true
check "a: feat/wip unmerged, 2 ahead, upstream gone" is o/a '.branches[] | select(.name == "feat/wip") | [.merged, .ahead, .gone] | join(",")' "false,2,true"
check "a: main is head and integration" is o/a '.branches[] | select(.name == "main") | [.head, .integration] | join(",")' "true,true"
# feat/other (the worktree's branch) sits on main's commit, so it counts as merged.
check "a: unmerged 1 (feat/wip)" is o/a .unmerged 1
check "a: feat/other merged, nothing beyond main" is o/a '.branches[] | select(.name == "feat/other") | [.merged, .ahead] | join(",")' "true,0"
check "a: worktrees main first" is o/a '.worktrees[0] | [.main, .path] | join(",")' "true,$A"
check "a: linked worktree with its branch and one changed path" is o/a '.worktrees[1] | [.main, .path, .branch, .dirty, .exists] | map(tostring) | join(",")' "false,$g/o/a-wt,feat/other,1,true"

check "b: detached" is o/b .detached true
check "b: no upstream, no remote" is o/b '[.upstream, .remote, .ahead] | map(tostring) | join(",")' "null,null,null"
check "b: integration main" is o/b .integration main

check "legacy: integration from the map" is o/legacy .integration master
check "legacy: topic unmerged by master" is o/legacy '.branches[] | select(.name == "topic") | .merged' false

table=$(repos)
check "table lists each repository" grep -q "^o/a " <<<"$table"
check "table says changed" grep -q "1 changed" <<<"$table"
check "table says unmerged" grep -q "1 unmerged" <<<"$table"
check "table says worktree" grep -q "1 worktree " <<<"$table"

# Operation in progress.
git -C "$g/o/legacy" switch -q topic
printf 'conflict\n' >"$g/o/legacy/f"
git -C "$g/o/legacy" commit -q -am "topic: f"
git -C "$g/o/legacy" switch -q master
printf 'other\n' >"$g/o/legacy/f"
git -C "$g/o/legacy" commit -q -am "master: f"
git -C "$g/o/legacy" merge -q topic >/dev/null 2>&1 || true
json=$(repos --json)
check "legacy: merge in progress" is o/legacy .operation merge
git -C "$g/o/legacy" merge --abort

# Actions.
out=$(repos path o/a)
check "path" [ "$out" = "$A" ]
out=$(repos path o/none 2>&1)
code=$?
check "path of a missing repository: exit 2" [ "$code" -eq 2 ]

out=$(repos branch-delete o/a feat/wip 2>&1)
code=$?
check "unmerged branch is refused (exit 3)" [ "$code" -eq 3 ]
check "...with git's reason on stdout" grep -q "not fully merged" <<<"$out"
check "...and still there" git -C "$A" show-ref -q --verify refs/heads/feat/wip
out=$(repos branch-delete o/a chore/done 2>&1)
code=$?
check "merged branch deleted" [ "$code" -eq 0 ]
check "...and gone" not git -C "$A" show-ref -q --verify refs/heads/chore/done

out=$(repos worktree-remove o/a "$g/o/a-wt" 2>&1)
code=$?
check "dirty worktree is refused (exit 3)" [ "$code" -eq 3 ]
check "...and still there" [ -d "$g/o/a-wt" ]
rm "$g/o/a-wt/new"
out=$(repos worktree-remove o/a "$g/o/a-wt" 2>&1)
code=$?
check "clean worktree removed" [ "$code" -eq 0 ]
check "...and gone" [ ! -d "$g/o/a-wt" ]

# Branch actions. feat/wip's upstream is gone; feat/other has none.
out=$(repos branch-publish o/a feat/wip 2>&1)
code=$?
check "publish recreates the gone upstream" [ "$code" -eq 0 ]
json=$(repos --json)
check "...no longer gone, in step" is o/a '.branches[] | select(.name == "feat/wip") | [.gone, .aheadUpstream, .behindUpstream] | map(tostring) | join(",")' "false,0,0"
check "a branch without an upstream has null counts" is o/a '.branches[] | select(.name == "feat/other") | [.aheadUpstream, .behindUpstream] | map(tostring) | join(",")' "null,null"
git -C "$A" switch -q feat/wip
commit "$A" wip3 "w" "feat: wip 3"
json=$(repos --json)
check "ahead of its upstream after a commit" is o/a '.branches[] | select(.name == "feat/wip") | .aheadUpstream' 1
out=$(repos branch-push o/a feat/wip 2>&1)
code=$?
check "push" [ "$code" -eq 0 ]
json=$(repos --json)
check "...now in step" is o/a '.branches[] | select(.name == "feat/wip") | .aheadUpstream' 0
out=$(repos branch-push o/a feat/other 2>&1)
code=$?
check "push without an upstream is refused (exit 3)" [ "$code" -eq 3 ]
git clone -q "$origin" "$root/other" 2>/dev/null
git -C "$root/other" switch -q feat/wip
commit "$root/other" theirs "t" "theirs"
git -C "$root/other" push -q origin feat/wip 2>/dev/null
git -C "$A" fetch -q
json=$(repos --json)
check "behind its upstream after their push" is o/a '.branches[] | select(.name == "feat/wip") | .behindUpstream' 1
out=$(repos branch-pull o/a main 2>&1)
code=$?
check "pull of a branch not checked out is refused (exit 3)" [ "$code" -eq 3 ]
out=$(repos branch-pull o/a feat/wip 2>&1)
code=$?
check "pull fast-forwards" [ "$code" -eq 0 ]
json=$(repos --json)
check "...and in step" is o/a '.branches[] | select(.name == "feat/wip") | .behindUpstream' 0
out=$(repos branch-switch o/a main 2>&1)
code=$?
check "switch with uncommitted changes is refused (exit 3)" [ "$code" -eq 3 ]
git -C "$A" checkout -q -- README
out=$(repos branch-switch o/a main 2>&1)
code=$?
check "switch when clean" [ "$code" -eq 0 ]
check "...is on main" [ "$(git -C "$A" symbolic-ref --short HEAD)" = main ]

rm -rf "$g/o/b"
git -C "$A" worktree add -q "$root/elsewhere" -b feat/else
rm -rf "$root/elsewhere"
json=$(repos --json)
check "a worktree whose directory is gone says so" is o/a '.worktrees[] | select(.path == "'"$root"'/elsewhere") | .exists' false
out=$(repos worktree-prune o/a 2>&1)
json=$(repos --json)
check "worktree-prune forgets it" [ "$(field o/a '[.worktrees[] | select(.path == "'"$root"'/elsewhere")] | length')" = 0 ]

out=$(repos fetch o/a 2>&1)
code=$?
check "fetch from the bare origin" [ "$code" -eq 0 ]
check "...reports it" grep -q "^o/a: fetched" <<<"$out"
json=$(repos --json)
check "...and fetched is now set" [ "$(field o/a .fetched)" != null ]
out=$(repos fetch o/legacy 2>&1)
code=$?
check "fetch with no remote is not an error" [ "$code" -eq 0 ]
check "...and says so" grep -q "no remote" <<<"$out"
git -C "$A" remote set-url origin "$root/missing.git"
out=$(repos fetch 2>&1)
code=$?
check "a failing fetch is exit 3" [ "$code" -eq 3 ]
check "...naming the repository" grep -q "^o/a: failed" <<<"$out"

# The config file, as the module writes it.
conf=$root/conf.json
printf '{"root":"%s","integration":{"o/legacy":"master"},"exclude":["o/legacy"]}\n' "$g" >"$conf"
json=$(env -u REPOS_ROOT -u REPOS_INTEGRATION -u REPOS_EXCLUDE REPOS_CONFIG="$conf" repos --json)
check "config file: root" [ "$(jq -r .root <<<"$json")" = "$g" ]
check "config file: exclude" not listed o/legacy
json=$(env -u REPOS_INTEGRATION -u REPOS_EXCLUDE REPOS_CONFIG="$conf" REPOS_EXCLUDE='[]' repos --json)
check "environment overrides a config field" jq -e '.repos[] | select(.id == "o/legacy") | select(.integration == "master")' <<<"$json" >/dev/null

# Owners: only the repositories of the named owners are listed (and fetched). A
# second owner, q, so there is something to leave out. By now o/b is gone and
# o/skip is excluded, so o lists o/a and o/legacy.
mkdir -p "$g/q"
for r in x y; do
  git init -q "$g/q/$r"
  commit "$g/q/$r" f "1" "one"
done
ids() { jq -r '.repos | map(.id) | join(",")' <<<"$json"; }

json=$(repos --json)
check "owners: none named lists every owner" [ "$(ids)" = "o/a,o/legacy,q/x,q/y" ]
json=$(REPOS_OWNERS='[]' repos --json)
check "owners: an empty list is the same" [ "$(ids)" = "o/a,o/legacy,q/x,q/y" ]
json=$(REPOS_OWNERS='["q"]' repos --json)
check "owners: only the named owner" [ "$(ids)" = "q/x,q/y" ]
json=$(REPOS_OWNERS='["o","q"]' repos --json)
check "owners: several, all of them" [ "$(ids)" = "o/a,o/legacy,q/x,q/y" ]
json=$(REPOS_OWNERS='["nobody"]' repos --json)
check "owners: a name matching nothing lists nothing, as valid JSON" [ "$(jq -c .repos <<<"$json")" = '[]' ]
json=$(REPOS_OWNERS='["q"]' REPOS_EXCLUDE='["q/y"]' repos --json)
check "owners: exclude still removes single repositories" [ "$(ids)" = "q/x" ]
out=$(REPOS_OWNERS='["q"]' repos)
check "owners: the table lists only that owner" [ "$(wc -l <<<"$out")" -eq 2 ]
check "...and not the other" not grep -q '^o/' <<<"$out"
out=$(REPOS_OWNERS='["q"]' repos fetch 2>&1)
check "owners: a bare fetch covers only that owner" [ "$out" = "$(printf 'q/x: no remote\nq/y: no remote')" ]
out=$(REPOS_OWNERS='["q"]' repos path o/a)
check "owners: a repository named explicitly is still found" [ "$out" = "$A" ]
printf '{"root":"%s","owners":["q"]}\n' "$g" >"$conf"
json=$(env -u REPOS_ROOT -u REPOS_EXCLUDE REPOS_CONFIG="$conf" repos --json)
check "config file: owners" [ "$(ids)" = "q/x,q/y" ]

# Changed paths are counted by content: a file whose size differs from the
# index's but whose content through a clean filter does not (dots' DMS
# settings.json) is listed by `git status` and is not a change. And `pull`:
# owner p, one origin, a clone that pushes and five that are behind it.
P=$root/p.git
git init -q --bare "$P"
git config --global filter.strip.clean "tr -d X"
mkdir -p "$g/p"
git clone -q "$P" "$g/p/pusher" 2>/dev/null
commit "$g/p/pusher" f "1" "one"
commit "$g/p/pusher" g "1" "two"
printf 's filter=strip\n' >"$g/p/pusher/.gitattributes"
commit "$g/p/pusher" s "abc" "three"
git -C "$g/p/pusher" add .gitattributes
git -C "$g/p/pusher" commit -q -m attributes
git -C "$g/p/pusher" push -q origin main
for r in up dirty-ok blocked diverged filter; do git clone -q "$P" "$g/p/$r" 2>/dev/null; done
commit "$g/p/pusher" f "2" "upstream changes f"
git -C "$g/p/pusher" push -q origin main
for r in up dirty-ok blocked diverged filter; do git -C "$g/p/$r" fetch -q; done
echo local >"$g/p/dirty-ok/g"
echo local >"$g/p/blocked/f"
commit "$g/p/diverged" h "1" "local only"
printf 'abcX\n' >"$g/p/filter/s"

check "filter: git status lists the file" [ -n "$(git -C "$g/p/filter" status --porcelain)" ]
json=$(REPOS_OWNERS='["p"]' repos --json)
check "filter: ...but it is not a changed path" is p/filter .dirty 0
check "a real change still counts" is p/dirty-ok .dirty 1
mkdir -p "$g/p/up/newdir"
touch "$g/p/up/newdir/a" "$g/p/up/newdir/b"
json=$(REPOS_OWNERS='["p"]' repos --json)
check "an untracked directory counts once, as git status shows it" is p/up .dirty 1
rm -rf "$g/p/up/newdir"

out=$(REPOS_OWNERS='["p"]' repos pull 2>&1)
code=$?
check "pull: one not fast-forwarded is exit 3" [ "$code" -eq 3 ]
check "pull: a clean one behind is pulled" grep -qx "p/up: pulled 1" <<<"$out"
check "pull: local changes the pull does not touch do not stop it" grep -qx "p/dirty-ok: pulled 1" <<<"$out"
check "pull: ...and are kept" [ "$(cat "$g/p/dirty-ok/g")" = local ]
check "pull: the filter's size-only change does not stop it" grep -qx "p/filter: pulled 1" <<<"$out"
check "pull: local changes in the way are refused" grep -qx "p/blocked: not pulled: local changes are in the way" <<<"$out"
check "pull: ...and kept" [ "$(cat "$g/p/blocked/f")" = local ]
check "pull: a diverged branch is refused" grep -qx "p/diverged: not pulled: diverged from its upstream" <<<"$out"
check "pull: ...and not merged" [ "$(git -C "$g/p/diverged" rev-list --count --merges HEAD)" = 0 ]
check "pull: one in step is up to date" grep -qx "p/pusher: up to date" <<<"$out"
out=$(REPOS_OWNERS='["p"]' repos pull p/up 2>&1)
code=$?
check "pull: one named, nothing to do, exit 0" [ "$code" -eq 0 ] && [ "$out" = "p/up: up to date" ]
out=$(repos pull o/legacy q/x 2>&1)
code=$?
check "pull: no remote is not an error" [ "$code" -eq 0 ]
check "...and says so" [ "$out" = "$(printf 'o/legacy: no remote\nq/x: no remote')" ]
git -C "$g/p/up" switch -q -c topic
out=$(repos pull p/up 2>&1)
check "pull: a branch with no upstream says so" [ "$out" = "p/up: no upstream" ]
git -C "$g/p/up" checkout -q --detach
out=$(repos pull p/up 2>&1)
check "pull: detached says so" [ "$out" = "p/up: detached" ]

repos nonsense >/dev/null 2>&1
check "unknown command is usage (64)" [ $? -eq 64 ]

echo
if [ "$fails" -eq 0 ]; then
  echo "all checks passed"
else
  echo "$fails check(s) failed"
  exit 1
fi
