#!/usr/bin/env bash
# repos: every git repository under one directory, at a glance, and the few
# safe things one does to them from a menu. Written for the DMS bar widget
# (modules/home/dank/plugins/dotsRepos), which runs `repos --json` when its
# popout opens; the table form is for a terminal.
#
#   repos                        one line per repository
#   repos --json                 the same as JSON ({root, generated, repos: [...]})
#   repos fetch [ID...]          git fetch --prune in the named repositories (all when none)
#   repos pull [ID...]           fast-forward each checked-out branch from its upstream (all when none)
#   repos push [ID...]           push every branch ahead of its upstream, merging cleanly first when diverged
#   repos branch-delete ID NAME  delete a local branch, only if it is merged (git branch -d)
#   repos worktree-remove ID DIR remove a linked worktree, only if it is clean (git worktree remove)
#   repos worktree-prune ID      forget worktrees whose directory is gone
#   repos branch-publish ID NAME push a branch with no upstream and set it (git push -u)
#   repos branch-push ID NAME    push a branch to its upstream (never forced)
#   repos branch-pull ID NAME    fast-forward the checked-out branch from its upstream
#   repos branch-switch ID NAME  check a branch out, only with a clean tree
#   repos path ID                print the repository's directory
#
# A repository is `<root>/<owner>/<name>` with a `.git` directory. A directory
# whose `.git` is a file is a linked worktree: it is listed under the repository
# it belongs to, not as a repository of its own. ID is `<owner>/<name>`.
#
# Per repository: the branch (or the detached commit), the integration branch
# (REPOS_INTEGRATION, a JSON map of ID to branch; else main, else master, else
# the current branch), the upstream and how far ahead and behind it HEAD is,
# the number of changed paths, an operation in progress (merge, rebase, ...),
# when the last fetch was, every local branch (with whether it is merged into
# the integration branch, how many commits it has beyond it, and whether its
# upstream is gone), and every worktree. Nothing here talks to a remote except
# `fetch`, `pull`, `push` and the push and pull of a branch, which never prompt: a
# repository that needs credentials the environment lacks is reported as failed.
#
# Which repositories are listed: every one under the root, minus those named in
# `exclude` (IDs) and, when `owners` is not empty, those of any other owner. The
# same set is what a bare `fetch`, `pull` or `push` covers. A repository named explicitly to a
# subcommand (`path`, `branch-delete`, ...) is found whatever the filters say.
#
# Configuration: REPOS_CONFIG names a JSON file {root, integration, exclude,
# owners} (written by package.nix from the dots.repos options); REPOS_ROOT,
# REPOS_INTEGRATION (the JSON map), REPOS_EXCLUDE and REPOS_OWNERS (JSON lists)
# override its fields. Without either, the root is ~/Documents/git.
#
# Exit codes: 0 done, 2 a repository or branch was not found, 3 git refused
# (unmerged branch, dirty worktree, failed fetch, a pull that could not
# fast-forward, a push that was refused), 64 bad usage.

# writeShellApplication turns errexit and pipefail on; this script checks every
# git call itself (a repository in an odd state must still be listed), so off.
set +o errexit +o pipefail
set -u

# REPOS_DEFAULT_CONFIG is the file the package was built with; REPOS_CONFIG
# names another.
config=${REPOS_CONFIG:-${REPOS_DEFAULT_CONFIG:-}}
conf() { # conf JQ-EXPR DEFAULT: a field of the config file, or DEFAULT
  if [ -n "$config" ] && [ -r "$config" ]; then
    jq -c "$1 // $2" "$config"
  else
    echo "$2"
  fi
}
root=${REPOS_ROOT:-$(conf '.root' '""' | jq -r .)}
root=${root:-$HOME/Documents/git}
root=${root%/}
integration_map=${REPOS_INTEGRATION:-$(conf '.integration' '{}')}
exclude=${REPOS_EXCLUDE:-$(conf '.exclude' '[]')}
owners=${REPOS_OWNERS:-$(conf '.owners' '[]')}

usage() {
  cat >&2 <<'EOF'
usage: repos                        one line per repository
       repos --json                 the same as JSON
       repos fetch [ID...]          git fetch --prune (all repositories when none named)
       repos pull [ID...]           git pull --ff-only (all repositories when none named)
       repos push [ID...]           push each branch ahead of its upstream (merging first only when clean)
       repos branch-delete ID NAME  delete a merged local branch
       repos worktree-remove ID DIR remove a clean linked worktree
       repos worktree-prune ID      forget worktrees whose directory is gone
       repos branch-publish ID NAME push a branch with no upstream and set it (git push -u)
       repos branch-push ID NAME    push a branch to its upstream (never forced)
       repos branch-pull ID NAME    fast-forward the checked-out branch from its upstream
       repos branch-switch ID NAME  check a branch out, only with a clean tree
       repos path ID                print the repository's directory
ID is <owner>/<name> under the root (REPOS_ROOT, default ~/Documents/git).
EOF
  exit 64
}

# Never block on a prompt: a fetch from a menu has no terminal to answer it.
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND=${GIT_SSH_COMMAND:-"ssh -o BatchMode=yes"}

# dirty_count DIR: the changed paths of a worktree, as `git status` counts
# them: staged, changed in the worktree, unmerged, untracked (an untracked
# directory once). Not `git status --porcelain` itself: git compares sizes
# before it runs a clean filter, so it lists a file whose size differs from
# the index's even when its cleaned content is the same (dots' DMS
# settings.json: `git diff` is empty, `git status` says M until a `git add`),
# and the menu then hid the pull of a tree with nothing in it. `git diff`
# compares the cleaned content.
dirty_count() {
  local d=$1
  {
    timeout 20 git -C "$d" --no-optional-locks diff --name-only -z
    timeout 20 git -C "$d" --no-optional-locks diff --cached --name-only -z
    timeout 20 git -C "$d" --no-optional-locks ls-files -z --others --exclude-standard --directory --no-empty-directory
  } 2>/dev/null | sort -zu | tr -cd '\0' | wc -c
}

# The directory of ID, or exit 2.
repo_dir() {
  local id=$1
  case $id in
    */*) ;;
    *)
      echo "repos: $id is not an owner/name" >&2
      exit 2
      ;;
  esac
  local dir=$root/$id
  if [ ! -d "$dir/.git" ]; then
    echo "repos: no repository at $dir" >&2
    exit 2
  fi
  printf '%s\n' "$dir"
}

# Every listed repository directory under the root, sorted: not excluded, and of
# an owner in `owners` when that list is not empty.
repo_dirs() {
  local gitdir
  for gitdir in "$root"/*/*/.git; do
    [ -d "$gitdir" ] || continue # a .git file is a linked worktree: listed by its repository
    local dir=${gitdir%/.git}
    local id=${dir#"$root"/}
    # One jq for both lists, so the cost per repository stays what it was.
    if ! jq -n -e --arg id "$id" --arg owner "${id%%/*}" --argjson ex "$exclude" --argjson ow "$owners" \
      '($ex | index($id)) == null and ($ow | length == 0 or index($owner) != null)' >/dev/null; then
      continue
    fi
    printf '%s\n' "$dir"
  done
}

# describe DIR: one JSON object on stdout.
describe() {
  local dir=$1
  local id=${dir#"$root"/}
  g() { git -C "$dir" --no-optional-locks "$@"; }

  local branch detached=false
  branch=$(g symbolic-ref --short -q HEAD) || {
    detached=true
    branch=$(g rev-parse --short HEAD 2>/dev/null || echo "?")
  }

  local integration
  integration=$(jq -r --arg id "$id" '.[$id] // empty' <<<"$integration_map")
  if [ -z "$integration" ]; then
    if g show-ref --verify -q refs/heads/main; then integration=main
    elif g show-ref --verify -q refs/heads/master; then integration=master
    else integration=$branch; fi
  fi

  local upstream remote ahead=null behind=null
  upstream=$(g rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
  remote=$(g remote 2>/dev/null | head -n 1)
  if [ -n "$upstream" ]; then
    local counts
    counts=$(g rev-list --left-right --count "$upstream...HEAD" 2>/dev/null || echo "")
    if [ -n "$counts" ]; then
      behind=${counts%%[[:space:]]*}
      ahead=${counts##*[[:space:]]}
    fi
  fi

  local dirty
  dirty=$(dirty_count "$dir")

  # Paths inside .git, absolute: this runs from another directory.
  gitpath() { g rev-parse --path-format=absolute --git-path "$1"; }

  local fetched=null f
  f=$(gitpath FETCH_HEAD)
  [ -e "$f" ] && fetched=$(stat -c %Y "$f")

  local operation=null p
  for p in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG; do
    [ -e "$(gitpath "$p")" ] && operation=\"${p%%_*}\" && break
  done
  if [ "$operation" = null ]; then
    for p in rebase-merge rebase-apply; do
      [ -d "$(gitpath "$p")" ] && operation='"REBASE"' && break
    done
  fi
  operation=${operation,,}

  # Local branches: name, upstream, track ("[gone]" when the upstream is gone).
  local merged
  merged=$(g branch --format='%(refname:short)' --merged "$integration" 2>/dev/null || true)
  local branches
  branches=$(
    g for-each-ref refs/heads --format='%(refname:short)%09%(upstream:short)%09%(upstream:track)' |
      while IFS=$'\t' read -r name up track; do
        local n_ahead is_merged=false
        n_ahead=$(g rev-list --count "$integration..$name" 2>/dev/null || echo 0)
        # Against its own upstream, for push and pull; null without one (or gone).
        up_ahead=null
        up_behind=null
        if [ -n "$up" ] && uc=$(g rev-list --left-right --count "$up...$name" 2>/dev/null); then
          up_behind=${uc%%[[:space:]]*}
          up_ahead=${uc##*[[:space:]]}
        fi
        grep -qx -- "$name" <<<"$merged" && is_merged=true
        jq -n -c --arg name "$name" --arg up "$up" --arg track "$track" --argjson ahead "$n_ahead" \
          --argjson upAhead "$up_ahead" --argjson upBehind "$up_behind" \
          --argjson merged "$is_merged" --arg head "$branch" --arg integration "$integration" '{
            name: $name,
            upstream: (if $up == "" then null else $up end),
            gone: ($track | test("gone")),
            ahead: $ahead,
            aheadUpstream: $upAhead,
            behindUpstream: $upBehind,
            merged: $merged,
            head: ($name == $head),
            integration: ($name == $integration)
          }'
      done | jq -s '.'
  )

  # Worktrees, the main one first; a linked worktree's own changed paths too.
  local worktrees
  worktrees=$(
    g worktree list --porcelain | awk -v RS= -F'\n' '{
      path=""; br=""; det="false"; bare="false"
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^worktree /) path = substr($i, 10)
        else if ($i ~ /^branch /) { br = substr($i, 8); sub(/^refs\/heads\//, "", br) }
        else if ($i == "detached") det = "true"
        else if ($i == "bare") bare = "true"
      }
      print path "\t" br "\t" det
    }' |
      while IFS=$'\t' read -r path wbranch wdet; do
        local wdirty=null main=false
        [ "$path" = "$dir" ] && main=true
        if [ "$main" = false ] && [ -d "$path" ]; then
          wdirty=$(dirty_count "$path")
        fi
        jq -n -c --arg path "$path" --arg branch "$wbranch" --argjson detached "$wdet" \
          --argjson main "$main" --argjson dirty "$wdirty" --argjson exists "$([ -d "$path" ] && echo true || echo false)" \
          '{path: $path, branch: (if $branch == "" then null else $branch end), detached: $detached, main: $main, dirty: $dirty, exists: $exists}'
      done | jq -s '.'
  )

  jq -n -c \
    --arg id "$id" --arg path "$dir" --arg branch "$branch" --argjson detached "$detached" \
    --arg integration "$integration" --arg upstream "$upstream" --arg remote "$remote" \
    --argjson ahead "$ahead" --argjson behind "$behind" --argjson dirty "$dirty" \
    --argjson fetched "$fetched" --argjson operation "$operation" \
    --argjson branches "$branches" --argjson worktrees "$worktrees" '{
      id: $id,
      owner: ($id | split("/")[0]),
      name: ($id | split("/")[1]),
      path: $path,
      branch: $branch,
      detached: $detached,
      integration: $integration,
      upstream: (if $upstream == "" then null else $upstream end),
      remote: (if $remote == "" then null else $remote end),
      ahead: $ahead,
      behind: $behind,
      dirty: $dirty,
      operation: $operation,
      fetched: $fetched,
      branches: $branches,
      unmerged: ($branches | map(select(.merged | not)) | length),
      worktrees: $worktrees
    }'
}

status_json() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  local i=0 dir
  while IFS= read -r dir; do
    describe "$dir" >"$tmp/$i.json" &
    i=$((i + 1))
  done < <(repo_dirs)
  wait
  if [ "$i" -eq 0 ]; then
    jq -n --arg root "$root" '{root: $root, generated: now | floor, repos: []}'
  else
    jq -s --arg root "$root" '{root: $root, generated: (now | floor), repos: sort_by(.id)}' "$tmp"/*.json
  fi
}

status_table() {
  status_json | jq -r '
    def num: if . == null then "-" else tostring end;
    .repos[] |
    [ .id,
      (.branch + (if .detached then " (detached)" else "" end)),
      (if .upstream == null then "no upstream" else "+" + (.ahead|num) + " -" + (.behind|num) end),
      (if .dirty > 0 then (.dirty|tostring) + " changed" else "clean" end),
      (if .unmerged > 0 then (.unmerged|tostring) + " unmerged" else "" end),
      (if (.worktrees|length) > 2 then ((.worktrees|length) - 1 | tostring) + " worktrees"
       elif (.worktrees|length) == 2 then "1 worktree" else "" end),
      (if .operation then "in " + .operation else "" end)
    ] | @tsv' | column -t -s $'\t'
}

cmd=${1:-}
case $cmd in
  "" | status) status_table ;;
  --json | json) status_json ;;
  fetch)
    shift
    failed=0
    if [ $# -eq 0 ]; then
      mapfile -t dirs < <(repo_dirs)
    else
      dirs=()
      for id in "$@"; do dirs+=("$(repo_dir "$id")"); done
    fi
    for dir in "${dirs[@]}"; do
      id=${dir#"$root"/}
      if [ -z "$(git -C "$dir" remote)" ]; then
        echo "$id: no remote"
        continue
      fi
      if out=$(timeout 60 git -C "$dir" fetch --prune --quiet 2>&1); then
        echo "$id: fetched"
      else
        echo "$id: failed: $(head -n 1 <<<"$out")"
        failed=1
      fi
    done
    [ "$failed" -eq 0 ] || exit 3
    ;;
  pull)
    # One line per repository, "ID: what happened": "pulled N", "up to date",
    # "not pulled: why" (the ones the menu marks), or "no remote", "no
    # upstream", "detached" (nothing to pull). Fast-forward only, never a
    # merge or a rebase; git itself decides whether local changes are in the
    # way (only those the pull would touch are). Exit 3 if any was not pulled.
    shift
    refused=0
    if [ $# -eq 0 ]; then
      mapfile -t dirs < <(repo_dirs)
    else
      dirs=()
      for id in "$@"; do dirs+=("$(repo_dir "$id")"); done
    fi
    for dir in "${dirs[@]}"; do
      id=${dir#"$root"/}
      if [ -z "$(git -C "$dir" remote)" ]; then
        echo "$id: no remote"
        continue
      fi
      if ! git -C "$dir" symbolic-ref -q HEAD >/dev/null; then
        echo "$id: detached"
        continue
      fi
      if ! git -C "$dir" rev-parse -q --verify '@{u}' >/dev/null 2>&1; then
        echo "$id: no upstream"
        continue
      fi
      before=$(git -C "$dir" rev-parse HEAD)
      if out=$(timeout 120 git -C "$dir" pull --ff-only --quiet 2>&1); then
        n=$(git -C "$dir" rev-list --count "$before..HEAD")
        if [ "$n" -eq 0 ]; then echo "$id: up to date"; else echo "$id: pulled $n"; fi
      else
        case $out in
          *"would be overwritten"*) why="local changes are in the way" ;;
          *"Not possible to fast-forward"* | *"not possible to fast-forward"*) why="diverged from its upstream" ;;
          *) why=$(grep -m 1 -E '^(fatal|error): ' <<<"$out" | sed -E 's/^(fatal|error): //')
             [ -n "$why" ] || why=$(grep -m 1 . <<<"$out") ;;
        esac
        echo "$id: not pulled: ${why:-git exited with an error}"
        refused=1
      fi
    done
    [ "$refused" -eq 0 ] || exit 3
    ;;
  push)
    # Every local branch whose upstream is a branch of the same name on a
    # remote, and which has commits the upstream lacks. Never forced, so the
    # remote can never lose a commit: git refuses anything that is not a
    # fast-forward of what it has.
    #
    # A branch that has diverged (the remote has commits it lacks too) is
    # merged first, but only when the merge is clean, and without touching
    # any working tree until it is known to be: `git merge-tree --write-tree`
    # computes it in memory and exits 1 on any conflict (content,
    # modify/delete, rename), and then nothing changes. A clean merge is
    # committed (both parents kept, so no commit of either side is dropped)
    # and the branch moved to it by a fast-forward: `git merge --ff-only` in
    # the worktree that has it checked out (git refuses if a local change is
    # in the way), or `git branch -f` otherwise (git refuses a branch that a
    # worktree, a rebase or a bisect is using). Never `-X ours`/`-X theirs`,
    # which settle a conflict by dropping one side.
    #
    # One line per branch that had something to push, "ID: BRANCH: pushed N",
    # "ID: BRANCH: merged R/B, pushed N" or "ID: BRANCH: [merged R/B, ]not
    # pushed: why", and per repository "ID: nothing to push", "ID: no remote"
    # or "ID: not pushed: fetch failed: why". Exit 3 if any was not pushed.
    shift
    refused=0
    if [ $# -eq 0 ]; then
      mapfile -t dirs < <(repo_dirs)
    else
      dirs=()
      for id in "$@"; do dirs+=("$(repo_dir "$id")"); done
    fi
    first_error() { # the first error line of git's output
      local why
      why=$(grep -m 1 -E '^(fatal|error|remote): ' <<<"$1" | sed -E 's/^(fatal|error|remote): //')
      [ -n "$why" ] || why=$(grep -m 1 '\[rejected\]\|\[remote rejected\]' <<<"$1" | sed -E 's/^ *! *//')
      [ -n "$why" ] || why=$(grep -m 1 . <<<"$1")
      printf '%s' "${why:-git exited with an error}"
    }
    for dir in "${dirs[@]}"; do
      id=${dir#"$root"/}
      if [ -z "$(git -C "$dir" remote)" ]; then
        echo "$id: no remote"
        continue
      fi
      # The remote's state now, not the last fetch's, to know what diverged.
      if ! out=$(timeout 60 git -C "$dir" fetch --all --prune --quiet 2>&1); then
        echo "$id: not pushed: fetch failed: $(first_error "$out")"
        refused=1
        continue
      fi
      any=0
      while IFS=$'\t' read -r b upref remote remoteref; do
        case $upref in refs/remotes/*) ;; *) continue ;; esac # no upstream, or a local one
        git -C "$dir" rev-parse -q --verify "$upref" >/dev/null || continue # gone
        up=${upref#refs/remotes/}
        ahead=$(git -C "$dir" rev-list --count "$upref..refs/heads/$b")
        [ "$ahead" -gt 0 ] || continue
        any=1
        if [ "$remoteref" != "refs/heads/$b" ]; then
          echo "$id: $b: not pushed: its upstream $up has another name (push it by hand)"
          refused=1
          continue
        fi
        merged=""
        behind=$(git -C "$dir" rev-list --count "refs/heads/$b..$upref")
        if [ "$behind" -gt 0 ]; then
          old=$(git -C "$dir" rev-parse "refs/heads/$b")
          theirs=$(git -C "$dir" rev-parse "$upref")
          out=$(git -C "$dir" merge-tree --write-tree --name-only --no-messages "$old" "$theirs" 2>&1)
          case $? in
            0) ;;
            1)
              n=$(tail -n +2 <<<"$out" | grep -c .)
              echo "$id: $b: not pushed: diverged from $up, and merging it conflicts in $n file(s)"
              refused=1
              continue
              ;;
            *)
              echo "$id: $b: not pushed: the merge failed: $(first_error "$out")"
              refused=1
              continue
              ;;
          esac
          tree=$(head -n 1 <<<"$out")
          if ! commit=$(git -C "$dir" commit-tree "$tree" -p "$old" -p "$theirs" \
            -m "Merge remote-tracking branch '$up' into $b" 2>&1); then
            echo "$id: $b: not pushed: the merge commit failed: $(first_error "$commit")"
            refused=1
            continue
          fi
          # The worktree that has the branch checked out, if any.
          wt=$(git -C "$dir" worktree list --porcelain | awk -v ref="refs/heads/$b" '
            /^worktree / { path = substr($0, 10) }
            $0 == "branch " ref { print path; exit }')
          if [ -n "$wt" ]; then
            out=$(git -C "$wt" merge --ff-only --quiet "$commit" 2>&1)
          else
            out=$(git -C "$dir" branch -f -- "$b" "$commit" 2>&1)
          fi
          # shellcheck disable=SC2181 # the status of whichever ran
          if [ $? -ne 0 ]; then
            case $out in
              *"would be overwritten"*) why="local changes are in the way" ;;
              *) why=$(first_error "$out") ;;
            esac
            echo "$id: $b: not pushed: diverged from $up; it merges cleanly, but $why"
            refused=1
            continue
          fi
          merged="merged $up, "
          ahead=$(git -C "$dir" rev-list --count "$upref..refs/heads/$b")
        fi
        if out=$(timeout 120 git -C "$dir" push --quiet "$remote" "refs/heads/$b:$remoteref" 2>&1); then
          echo "$id: $b: ${merged}pushed $ahead"
        else
          echo "$id: $b: ${merged}not pushed: $(first_error "$out")"
          refused=1
        fi
      done < <(git -C "$dir" for-each-ref refs/heads \
        --format='%(refname:short)%09%(upstream)%09%(upstream:remotename)%09%(upstream:remoteref)')
      [ "$any" -eq 1 ] || echo "$id: nothing to push"
    done
    [ "$refused" -eq 0 ] || exit 3
    ;;
  branch-delete)
    [ $# -eq 3 ] || usage
    dir=$(repo_dir "$2")
    git -C "$dir" branch -d -- "$3" 2>&1 || exit 3
    ;;
  worktree-remove)
    [ $# -eq 3 ] || usage
    dir=$(repo_dir "$2")
    git -C "$dir" worktree remove -- "$3" 2>&1 || exit 3
    ;;
  branch-publish)
    [ $# -eq 3 ] || usage
    dir=$(repo_dir "$2")
    remote=$(git -C "$dir" remote | head -n 1)
    [ -n "$remote" ] || {
      echo "$2: no remote"
      exit 3
    }
    timeout 120 git -C "$dir" push -u "$remote" "$3" 2>&1 || exit 3
    ;;
  branch-push)
    [ $# -eq 3 ] || usage
    dir=$(repo_dir "$2")
    up=$(git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name "$3@{u}" 2>/dev/null) || {
      echo "$3: no upstream (publish it first)"
      exit 3
    }
    timeout 120 git -C "$dir" push "${up%%/*}" "$3:${up#*/}" 2>&1 || exit 3
    ;;
  branch-pull)
    [ $# -eq 3 ] || usage
    dir=$(repo_dir "$2")
    [ "$(git -C "$dir" symbolic-ref --short -q HEAD)" = "$3" ] || {
      echo "$3 is not checked out"
      exit 3
    }
    timeout 120 git -C "$dir" pull --ff-only 2>&1 || exit 3
    ;;
  branch-switch)
    [ $# -eq 3 ] || usage
    dir=$(repo_dir "$2")
    [ "$(dirty_count "$dir")" -eq 0 ] || {
      echo "$2 has uncommitted changes"
      exit 3
    }
    git -C "$dir" switch "$3" 2>&1 || exit 3
    ;;
  worktree-prune)
    [ $# -eq 2 ] || usage
    dir=$(repo_dir "$2")
    git -C "$dir" worktree prune 2>&1 || exit 3
    ;;
  path)
    [ $# -eq 2 ] || usage
    repo_dir "$2"
    ;;
  help | -h | --help) usage ;;
  *)
    echo "repos: unknown command $cmd" >&2
    usage
    ;;
esac
