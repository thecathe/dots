#!/usr/bin/env bash
# repos: every git repository under one directory, at a glance, and the few
# safe things one does to them from a menu. Written for the DMS bar widget
# (modules/home/dank/plugins/dotsRepos), which runs `repos --json` when its
# popout opens; the table form is for a terminal.
#
#   repos                        one line per repository
#   repos --json                 the same as JSON ({root, generated, repos: [...]})
#   repos fetch [ID...]          git fetch --prune in the named repositories (all when none)
#   repos branch-delete ID NAME  delete a local branch, only if it is merged (git branch -d)
#   repos worktree-remove ID DIR remove a linked worktree, only if it is clean (git worktree remove)
#   repos worktree-prune ID      forget worktrees whose directory is gone
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
# `fetch`, which never prompts: a repository that needs credentials the
# environment lacks is reported as failed.
#
# Configuration: REPOS_CONFIG names a JSON file {root, integration, exclude}
# (written by package.nix from the dots.repos options); REPOS_ROOT,
# REPOS_INTEGRATION (the JSON map) and REPOS_EXCLUDE (a JSON list) override
# its fields. Without either, the root is ~/Documents/git.
#
# Exit codes: 0 done, 2 a repository or branch was not found, 3 git refused
# (unmerged branch, dirty worktree, failed fetch), 64 bad usage.

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

usage() {
  cat >&2 <<'EOF'
usage: repos                        one line per repository
       repos --json                 the same as JSON
       repos fetch [ID...]          git fetch --prune (all repositories when none named)
       repos branch-delete ID NAME  delete a merged local branch
       repos worktree-remove ID DIR remove a clean linked worktree
       repos worktree-prune ID      forget worktrees whose directory is gone
       repos path ID                print the repository's directory
ID is <owner>/<name> under the root (REPOS_ROOT, default ~/Documents/git).
EOF
  exit 64
}

# Never block on a prompt: a fetch from a menu has no terminal to answer it.
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND=${GIT_SSH_COMMAND:-"ssh -o BatchMode=yes"}

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

# Every repository directory under the root, sorted.
repo_dirs() {
  local gitdir
  for gitdir in "$root"/*/*/.git; do
    [ -d "$gitdir" ] || continue # a .git file is a linked worktree: listed by its repository
    local dir=${gitdir%/.git}
    local id=${dir#"$root"/}
    if jq -e --arg id "$id" 'index($id) != null' <<<"$exclude" >/dev/null; then
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
  dirty=$(timeout 20 git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null | wc -l)

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
        grep -qx -- "$name" <<<"$merged" && is_merged=true
        jq -n -c --arg name "$name" --arg up "$up" --arg track "$track" --argjson ahead "$n_ahead" \
          --argjson merged "$is_merged" --arg head "$branch" --arg integration "$integration" '{
            name: $name,
            upstream: (if $up == "" then null else $up end),
            gone: ($track | test("gone")),
            ahead: $ahead,
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
          wdirty=$(timeout 20 git -C "$path" --no-optional-locks status --porcelain 2>/dev/null | wc -l)
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
