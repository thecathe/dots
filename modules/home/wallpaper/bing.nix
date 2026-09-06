{
  config,
  pkgs,
  ...
}: let
  dms = "${config.programs.dank-material-shell.package}/bin/dms";
  jq = "${pkgs.jq}/bin/jq";

  # CLI wrapper around the wallpaperBing DMS plugin (see modules/home/dank/dms.nix)
  # and DMS core's own wallpaper-cycling feature, adding what neither provides:
  # a permanent, cross-host-synced favourites pool and a skip-to-favourites mode.
  #
  # Recents pool: ~/Pictures/BingWallpaper, owned by the plugin (deleteOld = false
  # + GnomeExtensionBingWallpaperCompatibility = true gives one dated file per day,
  # never overwritten - see dms.nix). Pruned here by bing-wallpaper-gc.
  #
  # Favourites pool: modules/home/wallpaper/favourites in this repo, git-tracked
  # so pinning on one host syncs to the other via a normal git pull. Plain copies,
  # not symlinks/hardlinks, so gc can prune a recents-pool original without
  # touching its pinned copy. Scripts only ever `git add`/`git rm` here - never
  # commit or push - so syncing stays part of the normal git workflow.
  binPin = pkgs.writeShellScriptBin "bing-wallpaper-pin" ''
    set -euo pipefail

    recents_dir="$HOME/Pictures/BingWallpaper"
    fav_dir="$HOME/dots/modules/home/wallpaper/favourites"
    metadata_file="$HOME/.cache/DankMaterialShell/bingwall/metadata.json"

    arg="''${1:-}"
    is_today=0

    if [ -z "$arg" ]; then
      if [ ! -f "$metadata_file" ]; then
        ${dms} ipc call toast warn "Bing wallpaper: no metadata yet, nothing to pin" || true
        exit 1
      fi
      target="$(${jq} -r '.currentImageSavePath' "$metadata_file")"
      is_today=1
    elif [ -f "$arg" ]; then
      target="$arg"
    else
      shopt -s nullglob
      matches=("$recents_dir/$arg"-*)
      shopt -u nullglob
      if [ "''${#matches[@]}" -eq 0 ]; then
        ${dms} ipc call toast warn "Bing wallpaper: no recents match '$arg'" || true
        exit 1
      fi
      target="''${matches[0]}"
    fi

    if [ ! -f "$target" ]; then
      ${dms} ipc call toast warn "Bing wallpaper: '$target' not found" || true
      exit 1
    fi

    mkdir -p "$fav_dir"
    name="$(basename "$target")"
    dest="$fav_dir/$name"

    if [ -e "$dest" ]; then
      ${dms} ipc call toast info "Bing wallpaper: '$name' already pinned" || true
      exit 0
    fi

    cp -n "$target" "$dest"
    git -C "$HOME/dots" add "$dest"

    if [ "$is_today" -eq 1 ]; then
      title="$(${jq} -r '.currentTitle // empty' "$metadata_file")"
      description="$(${jq} -r '.currentDescription // empty' "$metadata_file")"
      if [ -n "$title$description" ]; then
        sidecar="$fav_dir/''${name%.*}.json"
        ${jq} -n --arg title "$title" --arg description "$description" \
          '{title: $title, description: $description}' > "$sidecar"
        git -C "$HOME/dots" add "$sidecar"
      fi
    fi

    ${dms} ipc call toast info "Pinned $name - commit to sync to your other host" || true
  '';

  binUnpin = pkgs.writeShellScriptBin "bing-wallpaper-unpin" ''
    set -euo pipefail

    fav_dir="$HOME/dots/modules/home/wallpaper/favourites"

    arg="''${1:-}"
    if [ -z "$arg" ]; then
      ${dms} ipc call toast warn "Bing wallpaper: usage: bing-wallpaper-unpin <date|file>" || true
      exit 1
    fi

    if [ -f "$arg" ]; then
      target="$arg"
    else
      shopt -s nullglob
      matches=("$fav_dir/$arg"-*)
      shopt -u nullglob
      if [ "''${#matches[@]}" -eq 0 ]; then
        ${dms} ipc call toast warn "Bing wallpaper: no favourite matches '$arg'" || true
        exit 1
      fi
      target="''${matches[0]}"
    fi

    if [ ! -f "$target" ]; then
      ${dms} ipc call toast warn "Bing wallpaper: '$target' not found in favourites" || true
      exit 1
    fi

    name="$(basename "$target")"
    sidecar="$fav_dir/''${name%.*}.json"

    git -C "$HOME/dots" rm -f -q -- "$target"
    if [ -f "$sidecar" ]; then
      git -C "$HOME/dots" rm -f -q -- "$sidecar"
    fi

    # git rm removes the now-empty containing directory too once the last
    # tracked file is gone, so $fav_dir itself may no longer exist here.
    if [ -d "$fav_dir" ]; then
      remaining="$(find "$fav_dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | wc -l)"
    else
      remaining=0
    fi
    if [ "$remaining" -eq 0 ]; then
      ${dms} ipc call toast warn "Unpinned $name - favourites is now empty, skip mode has nothing to cycle" || true
    else
      ${dms} ipc call toast info "Unpinned $name - commit to sync" || true
    fi
  '';

  binList = pkgs.writeShellScriptBin "bing-wallpaper-list" ''
    set -euo pipefail

    recents_dir="$HOME/Pictures/BingWallpaper"
    fav_dir="$HOME/dots/modules/home/wallpaper/favourites"

    echo "Recent wallpapers ($recents_dir):"
    if [ -d "$recents_dir" ]; then
      find "$recents_dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | while read -r f; do
        name="$(basename "$f")"
        if [ -e "$fav_dir/$name" ]; then
          echo "  [pinned] $name"
        else
          echo "  $name"
        fi
      done
    else
      echo "  (none yet)"
    fi

    echo
    echo "Favourites ($fav_dir):"
    if [ -d "$fav_dir" ]; then
      find "$fav_dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | while read -r f; do
        echo "  $(basename "$f")"
      done
    else
      echo "  (none yet)"
    fi

    if [ "''${1:-}" = "--open" ]; then
      ${dms} ipc call dash toggle wallpaper || true
    fi
  '';

  binSkip = pkgs.writeShellScriptBin "bing-wallpaper-skip" ''
    set -euo pipefail

    fav_dir="$HOME/dots/modules/home/wallpaper/favourites"
    session_file="$HOME/dots/modules/home/dank/session.local.json"
    state_dir="$HOME/.cache/bing-wallpaper"
    state_file="$state_dir/skip-state.json"

    interval=3600
    if [ "''${1:-}" = "--interval" ]; then
      interval="''${2:?--interval requires a value}"
    fi

    shopt -s nullglob
    files=("$fav_dir"/*.jpg "$fav_dir"/*.jpeg "$fav_dir"/*.png "$fav_dir"/*.webp)
    shopt -u nullglob

    if [ "''${#files[@]}" -eq 0 ]; then
      ${dms} ipc call toast warn "Bing wallpaper: favourites is empty, nothing to skip to" || true
      exit 1
    fi

    mkdir -p "$state_dir"
    if [ ! -f "$state_file" ]; then
      ${jq} '{wallpaperPath, wallpaperCyclingEnabled, wallpaperCyclingMode, wallpaperCyclingInterval, wallpaperCyclingTime}' \
        "$session_file" > "$state_file"
    fi

    seed="''${files[0]}"
    tmp_file="$(mktemp)"
    ${jq} --arg path "$seed" --argjson interval "$interval" \
      '.wallpaperPath = $path
       | .wallpaperCyclingEnabled = true
       | .wallpaperCyclingMode = "interval"
       | .wallpaperCyclingInterval = $interval' \
      "$session_file" > "$tmp_file"
    mv "$tmp_file" "$session_file"

    ${dms} ipc call toast info "Skipping today's wallpaper - cycling through favourites" || true
  '';

  binResume = pkgs.writeShellScriptBin "bing-wallpaper-resume" ''
    set -euo pipefail

    session_file="$HOME/dots/modules/home/dank/session.local.json"
    metadata_file="$HOME/.cache/DankMaterialShell/bingwall/metadata.json"
    state_file="$HOME/.cache/bing-wallpaper/skip-state.json"

    tmp_file="$(mktemp)"

    if [ -f "$state_file" ]; then
      ${jq} -s '.[0] * .[1]' "$session_file" "$state_file" > "$tmp_file"
      mv "$tmp_file" "$session_file"
      rm -f "$state_file"
    else
      current=""
      if [ -f "$metadata_file" ]; then
        current="$(${jq} -r '.currentImageSavePath' "$metadata_file")"
      fi
      ${jq} --arg path "$current" \
        '.wallpaperCyclingEnabled = false
         | (if $path != "" then .wallpaperPath = $path else . end)' \
        "$session_file" > "$tmp_file"
      mv "$tmp_file" "$session_file"
    fi

    ${dms} ipc call toast info "Resumed today's Bing wallpaper" || true
  '';

  binGc = pkgs.writeShellScriptBin "bing-wallpaper-gc" ''
    set -euo pipefail

    recents_dir="$HOME/Pictures/BingWallpaper"

    days=30
    if [ "''${1:-}" = "--days" ]; then
      days="''${2:?--days requires a value}"
    fi

    if [ ! -d "$recents_dir" ]; then
      exit 0
    fi

    find "$recents_dir" -maxdepth 1 -type f -mtime "+$days" \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print -delete
  '';

  # Bing's own HPImageArchive endpoint only ever holds 8 days total (today +
  # 7 previous, confirmed empirically - idx 8+ just repeats the oldest entry),
  # so --count above 8 is a no-op past that point, not a Nix/plugin limitation.
  # Replicates the plugin's own URL-rewrite and OHR.-split filename logic
  # exactly (see BingwallDaemon.qml) so backfilled files use the identical
  # naming scheme and dedupe cleanly against whatever the daemon has already
  # downloaded for today.
  binBackfill = pkgs.writeShellScriptBin "bing-wallpaper-backfill" ''
    set -euo pipefail

    recents_dir="$HOME/Pictures/BingWallpaper"
    count=8
    mkt="''${LANG%%.*}"
    mkt="''${mkt//_/-}"
    if [ -z "$mkt" ]; then
      mkt="en-US"
    fi

    while [ $# -gt 0 ]; do
      case "$1" in
        --count) count="''${2:?--count requires a value}"; shift 2 ;;
        --mkt) mkt="''${2:?--mkt requires a value}"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
      esac
    done

    mkdir -p "$recents_dir"

    archive="$(curl -s "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=$count&mkt=$mkt")"

    fetched=0
    skipped=0

    while IFS= read -r image; do
      startdate="$(${jq} -r '.startdate' <<< "$image")"
      url_raw="$(${jq} -r '.url' <<< "$image")"
      image_url="''${url_raw%%&*}"
      image_url="''${image_url//1920x1080/UHD}"
      full_url="https://www.bing.com$image_url"
      name_part="''${image_url#*OHR.}"
      ext="''${name_part##*.}"
      file_name="''${name_part%.*}"
      dest="$recents_dir/$startdate-$file_name.$ext"

      if [ -e "$dest" ]; then
        skipped=$((skipped + 1))
        continue
      fi

      curl -s -o "$dest" "$full_url"
      fetched=$((fetched + 1))
    done < <(${jq} -c '.images[]' <<< "$archive")

    ${dms} ipc call toast info "Backfilled $fetched wallpaper(s), $skipped already present" || true
  '';
in {
  home.packages = [
    pkgs.curl
    pkgs.inotify-tools
    binPin
    binUnpin
    binList
    binSkip
    binResume
    binGc
    binBackfill
  ];

  # No existing daily trigger point in this repo fits (home-manager activation
  # only runs at rebuild time) - retention needs its own timer. Runs an hour
  # after the plugin's own dailyRefreshTime (09:00, dms.nix) so today's image
  # has already landed before pruning runs.
  systemd.user.services.bing-wallpaper-gc.Service = {
    Type = "oneshot";
    ExecStart = "${binGc}/bin/bing-wallpaper-gc";
  };
  systemd.user.timers.bing-wallpaper-gc = {
    Timer = {
      OnCalendar = "10:00";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };
}
