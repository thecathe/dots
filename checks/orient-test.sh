#!/usr/bin/env bash
# Behaviour of orient against real repositories: a devlog with a registry, a
# "github" made of bare repositories behind an insteadOf rewrite (so origin
# looks like https://github.com/<owner>/<name> and every fetch and push is
# real), and a second host that publishes to the same remotes. `gh` is a stub.
# Run by checks/orient.nix (orient, git, jq on PATH); run by hand the same way.
set -u

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
export HOME=$root/home GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
git config --global user.name tester
git config --global user.email tester@example.invalid
git config --global init.defaultBranch main
git config --global core.editor false # an editor opening anywhere is a failure
git config --global url."file://$root/remotes/".insteadOf "https://github.com/"

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
lacks() { [[ $1 != *"$2"* ]]; }
check_out() { # check_out NAME TEXT: the last run's stdout has TEXT
  if contains "$out" "$2"; then ok "$1"; else
    bad "$1"
    printf '      wanted: %s\n      stdout: %s\n' "$2" "$out"
  fi
}
check_no_out() { # check_no_out NAME TEXT: the last run's stdout lacks TEXT
  if lacks "$out" "$2"; then ok "$1"; else
    bad "$1"
    printf '      did not want: %s\n      stdout: %s\n' "$2" "$out"
  fi
}

# --- the world ---------------------------------------------------------------

devlog=$root/devlog
git init -q --bare "$root/devlog.git"
git clone -q "$root/devlog.git" "$devlog" 2>/dev/null
mkdir -p "$devlog/forest" "$devlog/dots"
echo "# forest" >"$devlog/forest/index.md"
echo "# dots" >"$devlog/dots/index.md"
git -C "$devlog" add -A
git -C "$devlog" commit -q -m "docs: seed"
git -C "$devlog" push -q origin main

cat >"$root/registry.toml" <<'EOF'
[defaults]
owners = ["thecathe"]
[defaults.effort]
sonnet = "xhigh"
opus = "medium"

[repos."thecathe/forest"]
[repos."thecathe/hosts"]
devlog = "dots"
[repos."thecathe/ocaml-forester"]
integration_branch = "redirect-meta"
upstream = "someone/ocaml-forester"
[repos."thecathe/membranes"]
integration_branch = ["main", "re-functoring"]
[repos."thecathe/devlog"]
devlog = false
[repos."butev/minidots"]
devlog = "dots"
push = true
EOF

# gh: GH_STUB says what it answers (private | public | fail); every call is logged.
cat >"$root/gh" <<EOF
#!/bin/sh
echo "\$*" >>"$root/gh.calls"
case \${GH_STUB:-private} in
  private) echo true ;;
  public) echo false ;;
  *) echo "gh: not logged in" >&2; exit 4 ;;
esac
EOF
chmod +x "$root/gh"

export ORIENT_DEVLOG_DIR=$devlog ORIENT_REGISTRY=$root/registry.toml ORIENT_GH=$root/gh
gh_calls() { cat "$root/gh.calls" 2>/dev/null || true; }

commit() { # commit REPO FILE CONTENT MESSAGE
  printf '%s\n' "$3" >"$1/$2"
  git -C "$1" add "$2"
  git -C "$1" commit -q -m "$4"
}
mkrepo() { # mkrepo OWNER NAME: a remote and a clone of it with one commit on main
  local d=$root/work/$1/$2
  git init -q --bare "$root/remotes/$1/$2.git"
  git init -q "$d"
  git -C "$d" remote add origin "https://github.com/$1/$2.git"
  commit "$d" f.txt one "feat: one"
  git -C "$d" push -q origin main
}
other_wb() { # other_wb OWNER NAME TEXT: the other host commits to dev/workbench and pushes it
  local d=$root/other/$1/$2
  [[ -d $d ]] || git clone -q "https://github.com/$1/$2.git" "$d" 2>/dev/null
  git -C "$d" fetch -q origin
  if git -C "$d" rev-parse -q --verify origin/dev/workbench >/dev/null; then
    git -C "$d" checkout -q -B dev/workbench origin/dev/workbench
  else
    git -C "$d" checkout -q -B dev/workbench origin/main
  fi
  mkdir -p "$d/dev"
  printf '%s\n' "$3" >"$d/dev/README.md"
  git -C "$d" add dev
  git -C "$d" commit -q -m "chore(dev): $3"
  git -C "$d" push -q origin dev/workbench
}
remote_ref() { git --git-dir="$root/remotes/$1/$2.git" rev-parse -q --verify "refs/heads/$3" 2>/dev/null || echo none; }
local_ref() { git -C "$root/work/$1/$2" rev-parse -q --verify "refs/heads/$3" 2>/dev/null || echo none; }
# Take the other host's workbench into a clone as a local branch, as a past session would have.
have_wb() { git -C "$root/work/$1/$2" fetch -q origin "dev/workbench:dev/workbench"; }

# run [orient args...] from $cwd: sets code, out (stdout), err (stderr)
run() {
  local o e
  o=$(mktemp -p "$root")
  e=$(mktemp -p "$root")
  (cd "$cwd" && orient "$@" >"$o" 2>"$e")
  code=$?
  out=$(<"$o")
  err=$(<"$e")
}
work() { cwd=$root/work/$1/$2; }

# --- the preamble ------------------------------------------------------------

mkdir -p "$root/plain"
cwd=$root/plain
run --hook
check "outside a repository: exit 0" test "$code" = 0
check "outside a repository: says nothing" test -z "$out"
run
check "by hand outside a repository: exit 0" test "$code" = 0
check "by hand outside a repository: only dlsync's progress, no preamble" contains "$out" "dlsync: up to date"
check_no_out "by hand outside a repository: no preamble" "orient:"

mkdir -p "$root/noorigin"
git init -q "$root/noorigin"
commit "$root/noorigin" f one "feat: one"
cwd=$root/noorigin
run --hook
check "no origin: exit 0 and says nothing" test "$code" = 0 -a -z "$out"

mkrepo thecathe forest
work thecathe forest
run --hook
check "forest: exit 0" test "$code" = 0
check_out "forest: names the repository and the owner" "orient: thecathe/forest (yours)"
check_out "forest: the devlog folder is the repo's name, with its index" "devlog: forest/ - read $devlog/forest/index.md first"
check_out "forest: integration is a local merge, no push" "integration: main; local git merge --no-ff (never squash); no push or PR unless asked"
check_out "forest: effort from the registry, other models ask" 'AI-marker effort: sonnet=xhigh, opus=medium; any other model: ask the author, or write "unrecorded"'
check "forest: the effort line comes last" contains "$(tail -n 1 <<<"$out")" "AI-marker effort"
check "forest: the header comes first" contains "$(head -n 1 <<<"$out")" "orient: thecathe/forest"
check_no_out "forest: no registry complaint" "registry:"
check_no_out "forest: no workbench line without a workbench" "workbench:"
check_no_out "success is silent about the sync" "dlsync:"
check "forest: stderr is empty" test -z "$err"

git -C "$cwd" worktree add -q "$root/wt-forest" -b feat/x
cwd=$root/wt-forest
run --hook
check_out "a linked worktree is the same repository" "orient: thecathe/forest (yours)"
git -C "$root/work/thecathe/forest" worktree remove --force "$root/wt-forest"

mkrepo thecathe hosts
work thecathe hosts
run --hook
check_out "devlog = \"dots\" in the registry" "devlog: dots/ - read $devlog/dots/index.md first"

mkrepo thecathe ocaml-forester
work thecathe ocaml-forester
run --hook
check_out "a recorded integration branch" "integration: redirect-meta; local git merge --no-ff"
check_out "an upstream is only where a PR would go" "upstream: someone/ocaml-forester (only where a PR would go"
check_out "no devlog folder for a repo that has none: ask first" "devlog: no folder ocaml-forester/ in $devlog yet; ask the author before starting one"
check_no_out "no effort line without a devlog folder" "AI-marker effort"

mkrepo thecathe membranes
work thecathe membranes
run --hook
check_out "two integration branches" "integration: main and re-functoring;"

mkrepo thecathe devlog
work thecathe devlog
run --hook
check_no_out "devlog = false: no devlog line" "devlog:"
check_no_out "devlog = false: no folder to ask about" "no folder"

mkrepo thecathe brandnew
work thecathe brandnew
run --hook
check_out "an unregistered repository of yours: defaults, and says so" "registry: no entry for thecathe/brandnew; defaults apply"
check_out "an unregistered repository of yours is still yours" "orient: thecathe/brandnew (yours)"

mkrepo someone else
work someone else
run --hook
check_out "someone else's repository is not yours" "orient: someone/else (not yours)"
check_out "someone else's repository goes by a PR" "integration: not yours (someone): finished work goes by a pull request on the remote; do not push to it"
check_no_out "someone else's repository: no devlog line" "devlog:"

mkrepo butev minidots
work butev minidots
run --hook
check_out "the explicit exception: pushes to origin, no PR" "integration: main; local git merge --no-ff (never squash), then push it to origin; no PR"
check_out "the exception keeps its devlog folder" "devlog: dots/"

# scp-like, ssh:// and https URLs all give an owner and a name.
git -C "$root/work/thecathe/forest" remote set-url origin git@github.com:thecathe/forest.git
cwd=$root/work/thecathe/forest
run --hook
check_out "an scp-like URL names the repository" "orient: thecathe/forest (yours)"
git -C "$cwd" remote set-url origin ssh://git@github.com:22/thecathe/forest.git
run --hook
check_out "an ssh:// URL names the repository" "orient: thecathe/forest (yours)"
git -C "$cwd" remote set-url origin https://github.com/thecathe/forest
run --hook
check_out "an https URL without .git names the repository" "orient: thecathe/forest (yours)"
git -C "$cwd" remote set-url origin https://github.com/thecathe/forest.git

# The registry: missing or broken, orient still says what it can.
saved=$ORIENT_REGISTRY
export ORIENT_REGISTRY=$root/nowhere.toml
run --hook
check "a missing registry: exit 0" test "$code" = 0
check_out "a missing registry: says so, repo still named" "registry: no registry at $root/nowhere.toml"
check_out "a missing registry: nobody is yours, so PR" "orient: thecathe/forest (not yours)"
printf 'this is = not [toml\n' >"$root/broken.toml"
export ORIENT_REGISTRY=$root/broken.toml
run --hook
check "a broken registry: exit 0" test "$code" = 0
check_out "a broken registry: says so" "registry: registry.toml does not parse"
printf '[repos]\nthing = 1\n' >"$root/odd.toml"
export ORIENT_REGISTRY=$root/odd.toml
run --hook
check "a registry of an odd shape: exit 0" test "$code" = 0
check_out "a registry of an odd shape: the repo is still named" "orient: thecathe/forest"
export ORIENT_REGISTRY=$saved

# --- the workbench -----------------------------------------------------------

mkrepo thecathe wb-local
work thecathe wb-local
git -C "$cwd" checkout -q -b dev/workbench
mkdir "$cwd/dev"
echo readme >"$cwd/dev/README.md"
git -C "$cwd" add dev
git -C "$cwd" commit -q -m "chore(dev): readme"
git -C "$cwd" checkout -q main
run --hook
check_out "a local-only workbench" "workbench: dev/workbench, local only, not on origin; README: git show dev/workbench:dev/README.md"

mkrepo thecathe wb-behind
other_wb thecathe wb-behind v1
work thecathe wb-behind
have_wb thecathe wb-behind
git -C "$cwd" fetch -q origin
other_wb thecathe wb-behind v2
run --hook
check_out "behind and not checked out: fast-forwarded" "workbench: dev/workbench, fast-forwarded 1 commit(s) from origin; README: git show origin/dev/workbench:dev/README.md"
check "behind: the local branch now equals origin's" test "$(local_ref thecathe wb-behind dev/workbench)" = "$(remote_ref thecathe wb-behind dev/workbench)"
run --hook
check_out "then it is level" "workbench: dev/workbench, level with origin"

mkrepo thecathe wb-clean
other_wb thecathe wb-clean v1
work thecathe wb-clean
have_wb thecathe wb-clean
git -C "$cwd" worktree add -q "$root/wt-clean" dev/workbench
other_wb thecathe wb-clean v2
run --hook
check_out "checked out and clean: fast-forwarded" "fast-forwarded 1 commit(s) from origin"
check "checked out and clean: the worktree has the new file" test "$(cat "$root/wt-clean/dev/README.md")" = v2
check "checked out and clean: the worktree is clean" test -z "$(git -C "$root/wt-clean" status --porcelain)"

mkrepo thecathe wb-dirty
other_wb thecathe wb-dirty v1
work thecathe wb-dirty
have_wb thecathe wb-dirty
git -C "$cwd" worktree add -q "$root/wt-dirty" dev/workbench
echo mine >>"$root/wt-dirty/dev/README.md"
other_wb thecathe wb-dirty v2
before=$(local_ref thecathe wb-dirty dev/workbench)
run --hook
check_out "checked out and dirty: left alone, and says why" "1 commit(s) behind origin; not updated, its checkout $root/wt-dirty has uncommitted changes"
check "checked out and dirty: the branch did not move" test "$(local_ref thecathe wb-dirty dev/workbench)" = "$before"
check "checked out and dirty: my edit is still there" contains "$(cat "$root/wt-dirty/dev/README.md")" mine

mkrepo thecathe wb-ahead
other_wb thecathe wb-ahead v1
work thecathe wb-ahead
have_wb thecathe wb-ahead
git -C "$cwd" worktree add -q "$root/wt-ahead" dev/workbench
commit "$root/wt-ahead" dev/extra.txt x "chore(dev): extra"
run --hook
check_out "ahead: says how to publish" "workbench: dev/workbench, 1 commit(s) ahead of origin (publish them with: orient push-workbench)"

mkrepo thecathe wb-diverged
other_wb thecathe wb-diverged v1
work thecathe wb-diverged
have_wb thecathe wb-diverged
git -C "$cwd" worktree add -q "$root/wt-diverged" dev/workbench
commit "$root/wt-diverged" dev/mine.txt x "chore(dev): mine"
other_wb thecathe wb-diverged v2
before=$(local_ref thecathe wb-diverged dev/workbench)
run --hook
check_out "diverged: reported, left alone" "diverged from origin (1 ahead, 1 behind); left alone, tell the author"
check "diverged: the branch did not move" test "$(local_ref thecathe wb-diverged dev/workbench)" = "$before"

mkrepo thecathe wb-remote-only
other_wb thecathe wb-remote-only v1
work thecathe wb-remote-only
run --hook
check_out "on origin only: no local branch here" "workbench: dev/workbench, on origin only; no local branch in this clone; README: git show origin/dev/workbench:dev/README.md"
check "on origin only: no local branch was created" test "$(local_ref thecathe wb-remote-only dev/workbench)" = none

mkrepo thecathe wb-gone
other_wb thecathe wb-gone v1
work thecathe wb-gone
git -C "$cwd" fetch -q origin
git --git-dir="$root/remotes/thecathe/wb-gone.git" update-ref -d refs/heads/dev/workbench
run --hook
check_no_out "a branch deleted on origin: no stale workbench" "workbench:"
check "a branch deleted on origin: the stale tracking ref is dropped" test -z "$(git -C "$cwd" for-each-ref refs/remotes/origin/dev)"

mkrepo thecathe wb-offline
other_wb thecathe wb-offline v1
work thecathe wb-offline
have_wb thecathe wb-offline
git -C "$cwd" fetch -q origin
git -C "$cwd" remote set-url origin https://github.com/thecathe/does-not-exist.git
run --hook
check "an unreachable origin: exit 0" test "$code" = 0
check_out "an unreachable origin: says so, with the last known state" "workbench: could not fetch origin"
check_out "an unreachable origin: still shows the workbench" "workbench: dev/workbench, level with origin"

# --- a failing sync ----------------------------------------------------------

work thecathe forest
echo dirty >>"$devlog/forest/index.md"
run --hook
check "dlsync fails, hook: exit 0 (the context is kept)" test "$code" = 0
check "dlsync fails, hook: stdout is JSON with a user message" jq -e '.systemMessage | startswith("orient: devlog sync failed: uncommitted changes")' <<<"$out" >/dev/null
check "dlsync fails, hook: the context carries the preamble" jq -e '.hookSpecificOutput | .hookEventName == "SessionStart" and (.additionalContext | contains("orient: thecathe/forest (yours)"))' <<<"$out" >/dev/null
check "dlsync fails, hook: and the failure" jq -e '.hookSpecificOutput.additionalContext | contains("NOT in step with its origin: uncommitted changes")' <<<"$out" >/dev/null
run
check "dlsync fails, by hand: dlsync's exit code" test "$code" = 10
check "dlsync fails, by hand: the headline is the first stderr line" contains "$(head -n 1 <<<"$err")" "orient: FAILED: uncommitted changes in the clone"
check_out "dlsync fails, by hand: the preamble is still printed" "orient: thecathe/forest (yours)"
cwd=$root/plain
run --hook
check "dlsync fails outside a repository: still told" jq -e '.hookSpecificOutput.additionalContext | contains("NOT in step")' <<<"$out" >/dev/null
git -C "$devlog" checkout -q -- forest/index.md
work thecathe forest
run --hook
check "once fixed: plain text again" test "$code" = 0 -a "${out:0:1}" != "{"

# A fetch failure (13) means offline: the workbench fetch is skipped, not tried again.
git -C "$devlog" remote set-url origin "$root/gone.git"
mkrepo thecathe wb-skip
other_wb thecathe wb-skip v1
work thecathe wb-skip
have_wb thecathe wb-skip
git -C "$cwd" fetch -q origin
other_wb thecathe wb-skip v2
before=$(local_ref thecathe wb-skip dev/workbench)
run --hook
check "offline: exit 0" test "$code" = 0
check "offline: the sync failure is reported" jq -e '.systemMessage | contains("could not fetch origin")' <<<"$out" >/dev/null
check "offline: the workbench was not fetched or moved" test "$(local_ref thecathe wb-skip dev/workbench)" = "$before"
git -C "$devlog" remote set-url origin "$root/devlog.git"

# --- usage -------------------------------------------------------------------

cwd=$root/plain
run --bogus
check "unknown argument: exit 64" test "$code" = 64
run push-workbench --hook
check "--hook with push-workbench: exit 64" test "$code" = 64
run --create
check "--create without push-workbench: exit 64" test "$code" = 64
run --help
check "--help: exit 0" test "$code" = 0
run push-workbench --force
check "an extra flag on push-workbench is refused, not passed to git" test "$code" = 64

# --- push-workbench ----------------------------------------------------------

pw() { # pw NAME: a clone of thecathe/NAME with a local dev/workbench (not yet on origin)
  mkrepo thecathe "$1"
  work thecathe "$1"
  git -C "$cwd" checkout -q -b dev/workbench
  mkdir "$cwd/dev"
  echo readme >"$cwd/dev/README.md"
  git -C "$cwd" add dev
  git -C "$cwd" commit -q -m "chore(dev): readme"
  git -C "$cwd" checkout -q main
}
headline() { head -n 1 <<<"$err"; }

: >"$root/gh.calls"
mkrepo someone theirs
work someone theirs
git -C "$cwd" branch dev/workbench
run push-workbench
check "someone else's repository: refused (20)" test "$code" = 20
check "someone else's repository: says why" contains "$(headline)" "someone/theirs is not yours"
check "someone else's repository: gh was never asked" test -z "$(gh_calls)"
check "someone else's repository: nothing on origin" test "$(remote_ref someone theirs dev/workbench)" = none

pw pw-nohost
git -C "$cwd" remote set-url origin "file://$root/remotes/thecathe/pw-nohost.git"
run push-workbench
check "origin not on github.com: refused (20)" test "$code" = 20
check "origin not on github.com: says why" contains "$(headline)" "is not on github.com"
check "origin not on github.com: nothing pushed" test "$(remote_ref thecathe pw-nohost dev/workbench)" = none

mkrepo thecathe pw-nobranch
work thecathe pw-nobranch
run push-workbench
check "no local workbench: refused (20)" test "$code" = 20
check "no local workbench: says so" contains "$(headline)" "there is no local dev/workbench"

pw pw-main
commit "$cwd" f.txt two "feat: two (main is ahead, and must stay unpushed)"
run push-workbench
check "first push without --create: refused (20)" test "$code" = 20
check "first push without --create: needs the author's yes" contains "$(headline)" "creating it needs the author's explicit yes"
check "first push without --create: names the command" contains "$err" "orient push-workbench --create"
check "first push without --create: nothing pushed" test "$(remote_ref thecathe pw-main dev/workbench)" = none
: >"$root/gh.calls"
run push-workbench --create
check "--create: exit 0" test "$code" = 0
check "--create: gh was asked about this repository" contains "$(gh_calls)" "repo view thecathe/pw-main --json isPrivate"
check "--create: says what it pushed" contains "$out" "pushed 1 commit(s) of dev/workbench to origin/dev/workbench"
check "--create: the remote has the branch, equal to the local one" test "$(remote_ref thecathe pw-main dev/workbench)" = "$(local_ref thecathe pw-main dev/workbench)"
check "main, which is ahead, was not pushed" test "$(remote_ref thecathe pw-main main)" != "$(local_ref thecathe pw-main main)"
run push-workbench
check "level: nothing to push, exit 0" test "$code" = 0
check "level: says so" contains "$out" "nothing to push"

git -C "$cwd" checkout -q dev/workbench
commit "$cwd" dev/more.txt more "chore(dev): more"
git -C "$cwd" checkout -q main
run push-workbench
check "ahead: pushed with no flag" test "$code" = 0
check "ahead: the remote caught up" test "$(remote_ref thecathe pw-main dev/workbench)" = "$(local_ref thecathe pw-main dev/workbench)"

other_wb thecathe pw-main theirs
before=$(remote_ref thecathe pw-main dev/workbench)
run push-workbench
check "behind: refused (20)" test "$code" = 20
check "behind: says it is not a fast-forward" contains "$(headline)" "not a fast-forward"
check "behind: the remote is untouched" test "$(remote_ref thecathe pw-main dev/workbench)" = "$before"
git -C "$cwd" checkout -q dev/workbench
commit "$cwd" dev/mine.txt mine "chore(dev): mine"
git -C "$cwd" checkout -q main
run push-workbench
check "diverged: refused (20), never forced" test "$code" = 20 -a "$(remote_ref thecathe pw-main dev/workbench)" = "$before"

pw pw-public
GH_STUB=public run push-workbench --create
check "public: refused (20)" test "$code" = 20
check "public: says why" contains "$(headline)" "is not private"
check "public: nothing pushed" test "$(remote_ref thecathe pw-public dev/workbench)" = none

pw pw-gh-fails
GH_STUB=fail run push-workbench --create
check "gh failing: refused as unknown (21)" test "$code" = 21
check "gh failing: treated as public" contains "$(headline)" "could not check whether thecathe/pw-gh-fails is private"
check "gh failing: nothing pushed" test "$(remote_ref thecathe pw-gh-fails dev/workbench)" = none

cwd=$root/plain
run push-workbench
check "outside a repository: refused (20)" test "$code" = 20

printf '\n%s failure(s)\n' "$fails"
exit $((fails > 0))
