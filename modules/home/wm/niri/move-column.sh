# niri-move-column left|right|up|down
#
# Moves the focused column to the monitor in that direction (what
# `move-column-to-monitor-<dir>` does) and makes it fill a portrait monitor's
# width while it is there, without losing the width it had.
#
# Why: niri looks up `default-column-width` only when a window opens, and keeps
# a column's width when it is moved. A 50% column moved to a portrait monitor
# would stay 50% of a screen that is too narrow for that, and nothing in niri's
# config can change it, hence this wrapper. Windows moved with the mouse, or
# opened there, are not handled by it (new windows get the output's own default).
#
# How: the column is *maximized* (niri's full-width flag) rather than set to
# 100%. niri keeps the column's own width underneath, so
#   - Mod+F on portrait un-maximizes to that width (a column set to 100% has
#     nothing to toggle to: niri resolves "maximized" as exactly 100%), and
#   - moving the column back undoes the maximize, so it returns to its own
#     width, scaled to the new monitor (niri keeps widths as proportions).
# niri does not report the flag over IPC, so the ids of the columns this script
# maximized are kept in $XDG_RUNTIME_DIR (gone at logout, which is when the
# windows are too), and "full width" is judged by size: the column was at least
# the monitor's width less the gaps on either side, i.e. a 100% or maximized
# column. NIRI_GAPS is read from config.kdl when the package is built.
#
# Decisions, all made on the column's state *before* the move, since the client
# has not resized yet right after it:
#   - nothing happens unless the move changed the focused monitor (the move does
#     nothing when there is no monitor that way, and the column must keep its width);
#   - a column that is already full width is not maximized again (the flag is a
#     toggle, and it would look the same);
#   - leaving portrait: a column this script maximized is un-maximized; any other
#     full-width column (opened there at 100%, or maximized by hand) gets the
#     default width; a column whose width was changed on portrait (Mod+R, Mod+F
#     off) is left alone;
#   - only tiled columns, and only a move between a non-portrait and a portrait
#     monitor, are touched. "Portrait" is judged by the logical size, which already
#     includes the monitor's rotation, so no monitor is named here.

# What a full-width column becomes when it leaves a portrait monitor without
# having been maximized by this script. Matches default-column-width in config.kdl.
default_width="50%"

dir="${1:-}"
case "$dir" in
left | right | up | down) ;;
*)
  echo "usage: niri-move-column left|right|up|down" >&2
  exit 2
  ;;
esac

state_dir="${XDG_RUNTIME_DIR:-/tmp}/niri-move-column"
state="$state_dir/maximized"

in_state() { [ -f "$state" ] && grep -qxF "$1" "$state"; }
state_add() {
  mkdir -p "$state_dir"
  in_state "$1" || echo "$1" >>"$state"
}
state_drop() {
  [ -f "$state" ] || return 0
  local tmp
  tmp="$(mktemp "$state.XXXXXX")"
  grep -vxF "$1" "$state" >"$tmp" || true
  mv "$tmp" "$state"
}
# Forget the windows that have been closed.
state_prune() {
  [ -f "$state" ] || return 0
  local live tmp
  live="$(niri msg --json windows | jq -r '.[].id')"
  tmp="$(mktemp "$state.XXXXXX")"
  grep -xF -f <(printf '%s\n' "$live") "$state" >"$tmp" || true
  mv "$tmp" "$state"
}

is_portrait() { jq -e '.logical != null and .logical.height > .logical.width' >/dev/null; }

# `null` (nothing focused) makes jq print nothing, which is "no value" below.
win="$(niri msg --json focused-window)"
out="$(niri msg --json focused-output)"
wid="$(printf '%s' "$win" | jq -r '.id // empty')"
floating="$(printf '%s' "$win" | jq -r '.is_floating // false')"
tile_w="$(printf '%s' "$win" | jq -r '.layout.tile_size[0] // empty')"
before="$(printf '%s' "$out" | jq -r '.name // empty')"

niri msg action "move-column-to-monitor-$dir"

out_after="$(niri msg --json focused-output)"
after="$(printf '%s' "$out_after" | jq -r '.name // empty')"

# Not moved (or nothing to compare), or not a tiled column: leave the width alone.
if [ -z "$before" ] || [ -z "$after" ] || [ "$before" = "$after" ] ||
  [ -z "$wid" ] || [ -z "$tile_w" ] || [ "$floating" != "false" ]; then
  exit 0
fi

from_portrait=false
printf '%s' "$out" | is_portrait && from_portrait=true
to_portrait=false
printf '%s' "$out_after" | is_portrait && to_portrait=true

# Was the column at full width on the monitor it came from?
looks_full() {
  printf '%s' "$out" | jq -e --argjson t "$tile_w" --argjson g "$NIRI_GAPS" \
    '.logical.width - 2 * $g - 1 <= $t' >/dev/null
}

state_prune

if [ "$from_portrait" = false ] && [ "$to_portrait" = true ]; then
  if ! looks_full; then
    niri msg action maximize-column
    state_add "$wid"
  fi
elif [ "$from_portrait" = true ] && [ "$to_portrait" = false ]; then
  if in_state "$wid"; then
    if looks_full; then
      niri msg action maximize-column
    fi
  elif looks_full; then
    niri msg action set-column-width "$default_width"
  fi
  state_drop "$wid"
fi
