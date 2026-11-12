#!/usr/bin/env bash
# code-workspace: open a pinned VSCode workspace, offering to clone any repos
# it needs that are missing on this host.
#
#   code-workspace <name>                    open ~/workspaces/vscode/<name>.code-workspace
#                                            (prompts to clone missing repos first)
#   code-workspace --on <host> [name]        open the workspace on a Remote-SSH host from the
#                                            manifest's "remotes" (no name: the host's home folder)
#   code-workspace --clone-missing [name|all]  clone missing repos, no prompt
#   code-workspace --sync-profiles           copy profile choices made in VSCode
#                                            (storage.json) into manifest.json
#   code-workspace --sync-entries            (re)generate launcher entries, prune stale ones
#   code-workspace --check                   report unmapped folders and unknown profiles
#
# Data (workspace files + manifest.json) lives in a separate private repo checked
# out at ~/workspaces; this tool is data-agnostic. Everything is read at runtime, so
# editing the data needs no rebuild, only --sync-entries for new/removed workspaces.

root=${CODE_WORKSPACE_DIR:-$HOME/workspaces/vscode}
manifest=${CODE_WORKSPACE_MANIFEST:-$root/manifest.json}
storage=${CODE_WORKSPACE_STORAGE:-$HOME/.config/Code/User/globalStorage/storage.json}
apps=${XDG_DATA_HOME:-$HOME/.local/share}/applications
log=${XDG_STATE_HOME:-$HOME/.local/state}/code-workspace.log

die() {
  echo "code-workspace: $*" >&2
  command -v notify-send >/dev/null && notify-send -a code-workspace "code-workspace" "$*" || true
  exit 1
}

warn() {
  echo "code-workspace: warning: $*" >&2
  command -v notify-send >/dev/null && notify-send -a code-workspace "code-workspace" "$*" || true
}

# The relative folder paths in the workspace files are right for exactly one
# location of those files. VSCode resolves them against the path a file was opened
# by: a launcher or the CLI keeps a symlink's path, but VSCode's own file dialog
# hands back the real path, so through a symlink one file means two different
# things (and one of them points at folders that don't exist). It also writes any
# new relative path relative to whichever it was opened by. So $root must be a real
# directory: true when resolving symlinks leaves its position under $HOME unchanged
# (a symlinked $HOME itself is fine, it shifts both sides alike).
real_root() {
  local real home_real
  [ -d "$root" ] || return 0
  real=$(realpath "$root") && home_real=$(realpath "$HOME") || return 1
  [ "${real#"$home_real"/}" = "${root#"$HOME"/}" ]
}

SYMLINK_MSG="$root is reached through a symlink, so a workspace opened from VSCode's file dialog resolves its folders against a different path than one opened from the launcher. Make it a real directory (see the workspaces repo README)."

# Folder paths of a workspace as repo-relative-to-$HOME paths. Collapsed
# lexically (realpath -s), which is where VSCode resolves them as long as real_root holds.
folders() {
  jq -r '.folders[].path' "$root/$1.code-workspace" | while read -r p; do
    abs=$(realpath -m -s "$root/$p")
    echo "${abs#"$HOME"/}"
  done
}

# Echo "<repo-key> <url>" for the longest repo key covering path $1, if any.
repo_for() {
  jq -r --arg p "$1" '
    .repos | to_entries
    | map(select(.key as $k | $p == $k or ($p | startswith($k + "/"))))
    | sort_by(.key | length) | last // empty
    | "\(.key) \(.value)"' "$manifest"
}

is_untracked() {
  jq -e --arg p "$1" '.untracked | any(. as $k | $p == $k or ($p | startswith($k + "/")))' "$manifest" >/dev/null
}

# Sets globals: to_clone (lines "key url"), unfixable (lines of paths).
find_missing() {
  to_clone=""
  unfixable=""
  while read -r rel; do
    [ -e "$HOME/$rel" ] && continue
    if hit=$(repo_for "$rel") && [ -n "$hit" ]; then
      to_clone+="$hit"$'\n'
    else
      unfixable+="$rel"$'\n'
    fi
  done < <(folders "$1")
  to_clone=$(printf '%s' "$to_clone" | sort -u | awk '{ print length($1), $0 }' | sort -n | cut -d' ' -f2-)
  unfixable=$(printf '%s' "$unfixable" | sort -u)
}

clone_missing() {
  local ok=1 key url
  mkdir -p "$(dirname "$log")"
  while read -r key url; do
    [ -z "$key" ] && continue
    [ -e "$HOME/$key" ] && continue # a parent clone may have created it
    mkdir -p "$(dirname "$HOME/$key")"
    echo "cloning $url -> ~/$key" | tee -a "$log"
    git clone "$url" "$HOME/$key" >>"$log" 2>&1 || {
      ok=0
      echo "clone failed: $url (see $log)" >&2
      command -v notify-send >/dev/null && notify-send -a code-workspace "Clone failed" "$url" || true
    }
  done <<<"$to_clone"
  [ "$ok" = 1 ]
}

# prompt <title> <option>... ; echoes the chosen option.
prompt() {
  local title=$1
  shift
  if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v fuzzel >/dev/null; then
    printf '%s\n' "$@" | fuzzel --dmenu --lines "$#" --prompt "$title: "
  else
    echo "$title" >&2
    select o in "$@"; do
      echo "$o"
      break
    done </dev/tty
  fi
}

profile_of() {
  jq -r --arg n "$1" '.profiles[$n] // "default"' "$manifest"
}

launch() {
  local name=$1 profile
  [ -f "$root/$name.code-workspace" ] || die "no workspace '$name' in $root"
  real_root || warn "$SYMLINK_MSG"
  find_missing "$name"
  if [ -n "$to_clone" ]; then
    n=$(printf '%s\n' "$to_clone" | grep -c .)
    choice=$(prompt "'$name' is missing $n repo(s)" "Clone missing repos and open" "Open anyway" "Cancel") || exit 0
    case $choice in
      Clone*) clone_missing || die "some clones failed, see $log" ;;
      Open*) ;;
      *) exit 0 ;;
    esac
  fi
  [ -n "$unfixable" ] && echo "note: untracked folders absent on this host: $unfixable" >&2
  profile=$(profile_of "$name")
  if [ "$profile" = default ]; then
    exec code "$root/$name.code-workspace"
  else
    exec code --profile "$profile" "$root/$name.code-workspace"
  fi
}

# Remote-SSH hosts. The manifest's "remotes" maps an ssh host alias to
#   { "home": "<its $HOME>", "workspaces": ["<name>", ...] }
# and the workspaces listed get a launcher entry that opens them on that host.
# Nothing is generated per remote: the workspace files are the ones in this very
# repo, checked out at the same place under the remote's $HOME (the layout is
# identical on every host), so the remote window opens the copy on the host and
# its relative folder paths resolve there, just as they do here.

# The remote's $HOME; empty unless the manifest gives an absolute one.
remote_home() {
  jq -r --arg h "$1" '.remotes[$h].home | strings | select(startswith("/"))' "$manifest"
}

remote_hosts() {
  jq -r '.remotes // {} | keys[]' "$manifest"
}

remote_workspaces() {
  jq -r --arg h "$1" '.remotes[$h].workspaces // [] | .[]' "$manifest"
}

# vscode-remote://ssh-remote+<host><path>, the path percent-encoded segment by segment.
remote_uri() {
  printf 'vscode-remote://ssh-remote+%s%s' "$1" \
    "$(jq -rn --arg p "$2" '$p | split("/") | map(@uri) | join("/")')"
}

launch_remote() {
  local host=$1 name=${2:-} home rel profile
  home=$(remote_home "$host")
  [ -n "$home" ] || die "no remote '$host' with an absolute \"home\" in $manifest"
  if [ -z "$name" ]; then
    exec code --folder-uri "$(remote_uri "$host" "$home")"
  fi
  [ -f "$root/$name.code-workspace" ] || die "no workspace '$name' in $root"
  rel=${root#"$HOME"/}
  [ "$rel" != "$root" ] || die "$root is not under $HOME, so its place under $host's home is unknown"
  profile=$(profile_of "$name")
  if [ "$profile" = default ]; then
    exec code --file-uri "$(remote_uri "$host" "$home/$rel/$name.code-workspace")"
  else
    exec code --profile "$profile" --file-uri "$(remote_uri "$host" "$home/$rel/$name.code-workspace")"
  fi
}

sync_profiles() {
  [ -f "$storage" ] || die "no $storage"
  local tmp
  tmp=$(mktemp)
  jq -S --slurpfile s "$storage" --arg root "file://$root/" '
    ($s[0].userDataProfiles | map({(.location): .name}) | add) as $names
    | ($s[0].profileAssociations.workspaces
       | to_entries
       | map(select(.key | startswith($root) and endswith(".code-workspace")))
       | map({key: (.key | ltrimstr($root) | rtrimstr(".code-workspace")),
              value: ($names[.value] // (if .value == "__default__profile__" then "default" else .value end))})
       | from_entries) as $assoc
    | .profiles = ((.profiles | with_entries(select(.key as $k | ($assoc | has($k)) | not)))
                    + ($assoc | with_entries(select(.value != "default"))))
  ' "$manifest" >"$tmp"
  mv "$tmp" "$manifest"
  git -C "$(dirname "$manifest")" diff --stat -- "$manifest" 2>/dev/null || true
}

WS_MARK="# Generated by code-workspace"

workspace_names() {
  find "$root" -maxdepth 1 -name '*.code-workspace' -printf '%f\n' | sed 's/\.code-workspace$//' | sort
}

# Entries written by the current sync_entries run, so the rest can be pruned.
declare -A wanted=()

# write_entry <file> <name> <comment> <exec>
write_entry() {
  cat >"$apps/$1" <<EOT
$WS_MARK
[Desktop Entry]
Type=Application
Name=$2
Comment=$3
Exec=$4
Icon=vscode
Terminal=false
Categories=Development;IDE;
EOT
  wanted[$1]=1
}

sync_entries() {
  # No data on this host (e.g. the private repo isn't cloned): nothing to do.
  [ -f "$manifest" ] || exit 0
  local self n f host here
  self=$(readlink -f "$0")
  mkdir -p "$apps"
  for n in $(workspace_names); do
    write_entry "code-workspace-$n.desktop" "Code: $n" \
      "VSCode workspace ($(profile_of "$n") profile)" "$self $n"
  done
  # The remotes, except the host this is running on (it would connect to itself).
  here=$(uname -n)
  for host in $(remote_hosts); do
    [ "$host" = "$here" ] && continue
    [ -n "$(remote_home "$host")" ] || continue # --check reports it
    write_entry "code-remote-$host.desktop" "Code ($host)" \
      "VSCode on $host over SSH" "$self --on $host"
    for n in $(remote_workspaces "$host"); do
      [ -f "$root/$n.code-workspace" ] || continue # --check reports it
      write_entry "code-remote-$host--$n.desktop" "Code ($host): $n" \
        "VSCode workspace on $host ($(profile_of "$n") profile)" "$self --on $host $n"
    done
  done
  # Prune entries we generated that are no longer wanted.
  for f in "$apps"/code-workspace-*.desktop "$apps"/code-remote-*.desktop; do
    [ -e "$f" ] || continue
    head -n1 "$f" | grep -qxF "$WS_MARK" || continue
    [ -n "${wanted[${f##*/}]:-}" ] || rm -- "$f"
  done
}

check() {
  local bad=0 n rel known host
  [ -f "$manifest" ] || die "no manifest at $manifest"
  if ! real_root; then
    echo "workspace dir: $SYMLINK_MSG"
    bad=1
  fi
  for n in $(workspace_names); do
    while read -r rel; do
      if [ -z "$(repo_for "$rel")" ] && ! is_untracked "$rel"; then
        echo "$n: folder ~/$rel is neither a mapped repo nor untracked"
        bad=1
      fi
    done < <(folders "$n")
  done
  for n in $(jq -r '.profiles | keys[]' "$manifest"); do
    [ -f "$root/$n.code-workspace" ] || { echo "profiles: no workspace file for '$n'"; bad=1; }
  done
  for host in $(remote_hosts); do
    [ -n "$(remote_home "$host")" ] || { echo "remotes: '$host' needs \"home\", the absolute path of its \$HOME"; bad=1; }
    for n in $(remote_workspaces "$host"); do
      [ -f "$root/$n.code-workspace" ] || { echo "remotes: '$host' lists '$n', which has no workspace file"; bad=1; }
    done
  done
  if [ -f "$storage" ]; then
    known=$(jq -r '.userDataProfiles[].name' "$storage")
    for p in $(jq -r '.profiles[]' "$manifest" | sort -u); do
      grep -qxF "$p" <<<"$known" || { echo "profiles: '$p' is not a VSCode profile on this host"; bad=1; }
    done
  fi
  [ "$bad" = 0 ] && echo ok
  exit "$bad"
}

case ${1:-} in
  --sync-entries) sync_entries ;;
  --check) check ;;
  --on)
    [ -n "${2:-}" ] || die "usage: code-workspace --on <host> [name]"
    launch_remote "$2" "${3:-}"
    ;;
  --sync-profiles) sync_profiles ;;
  --clone-missing)
    target=${2:-all}
    if [ "$target" = all ]; then
      names=$(workspace_names)
    else
      names=$target
    fi
    for n in $names; do
      find_missing "$n"
      [ -n "$to_clone" ] && clone_missing
    done
    ;;
  ""|-h|--help) sed -n '/^# code-workspace:/,/^$/p' "$0" ;;
  *) launch "$1" ;;
esac
