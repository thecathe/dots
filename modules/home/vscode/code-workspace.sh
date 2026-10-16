#!/usr/bin/env bash
# code-workspace: open a pinned VSCode workspace, offering to clone any repos
# it needs that are missing on this host.
#
#   code-workspace <name>                    open ~/workspaces/vscode/<name>.code-workspace
#                                            (prompts to clone missing repos first)
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
log=${XDG_STATE_HOME:-$HOME/.local/state}/code-workspace.log

die() {
  echo "code-workspace: $*" >&2
  command -v notify-send >/dev/null && notify-send -a code-workspace "code-workspace" "$*" || true
  exit 1
}

# Folder paths of a workspace as repo-relative-to-$HOME paths. Collapsed
# lexically (realpath -s): VSCode resolves against the symlink location.
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

sync_entries() {
  # No data on this host (e.g. the private repo isn't cloned): nothing to do.
  [ -f "$manifest" ] || exit 0
  local apps=${XDG_DATA_HOME:-$HOME/.local/share}/applications self n f
  self=$(readlink -f "$0")
  mkdir -p "$apps"
  for n in $(workspace_names); do
    cat >"$apps/code-workspace-$n.desktop" <<EOF
$WS_MARK
[Desktop Entry]
Type=Application
Name=Code: $n
Comment=VSCode workspace ($(profile_of "$n") profile)
Exec=$self $n
Icon=vscode
Terminal=false
Categories=Development;IDE;
EOF
  done
  # Prune entries we generated for workspaces that no longer exist.
  for f in "$apps"/code-workspace-*.desktop; do
    [ -e "$f" ] || continue
    head -n1 "$f" | grep -qxF "$WS_MARK" || continue
    n=${f##*/code-workspace-}
    n=${n%.desktop}
    [ -f "$root/$n.code-workspace" ] || rm -- "$f"
  done
}

check() {
  local bad=0 n rel known
  [ -f "$manifest" ] || die "no manifest at $manifest"
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
  ""|-h|--help) sed -n '2,10p' "$0" ;;
  *) launch "$1" ;;
esac
