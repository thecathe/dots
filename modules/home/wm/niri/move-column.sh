# niri-move-column left|right|up|down
#
# Moves the focused column to the monitor in that direction (what
# `move-column-to-monitor-<dir>` does) and, if it landed on a portrait monitor,
# makes it 100% of that monitor's width.
#
# Why: niri looks up `default-column-width` only when a window opens. A column
# keeps the width it has when it is moved, so a 50% column moved to a portrait
# monitor stays 50% of a screen that is too narrow for that. Nothing in niri's
# config can change this, hence this wrapper. Windows moved with the mouse, or
# opened there, are not touched by it (new windows get the output's own default).
#
# It only resizes when the move really changed the focused monitor: the move
# does nothing when there is no monitor that way, and then the column must keep
# whatever width it had. A column moved to a landscape monitor keeps its width.
#
# "Portrait" is judged by the logical size, which already includes the
# monitor's rotation, so no monitor is named here.

dir="${1:-}"
case "$dir" in
left | right | up | down) ;;
*)
  echo "usage: niri-move-column left|right|up|down" >&2
  exit 2
  ;;
esac

# `null` (no focused output) makes jq print nothing, which is "no name" below.
focused_name() { jq -r '.name // empty'; }

before="$(niri msg --json focused-output | focused_name)"

niri msg action "move-column-to-monitor-$dir"

after_json="$(niri msg --json focused-output)"
after="$(printf '%s' "$after_json" | focused_name)"

# Not moved (or nothing to compare): leave the width alone.
if [ -z "$before" ] || [ -z "$after" ] || [ "$before" = "$after" ]; then
  exit 0
fi

if printf '%s' "$after_json" | jq -e '.logical != null and .logical.height > .logical.width' >/dev/null; then
  niri msg action set-column-width "100%"
fi
