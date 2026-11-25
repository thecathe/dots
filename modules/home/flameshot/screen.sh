# flameshot-screen: Print with `dots.flameshot.pointerOutput`. Opens Flameshot's
# overlay on the output the pointer is on, without its "which output?" picker.
#
# `flameshot screen --edit -n N` takes N as an index into Qt's list of screens
# (`QGuiApplication::screens()`), and Qt lists them in the order the compositor
# announced its wl_output globals to this process. That is not a fixed order: an
# output that is switched off and on again is announced anew, after the others
# (niri's log shows `HDMI-A-1` disconnect and connect, and `wayland-info` then
# lists `DP-1` first). A fixed list of connector names went wrong as soon as that
# happened, and the overlay opened on the other monitor, from either one.
#
# So the order is read when Print is pressed, from the same place Qt reads it:
# `wayland-info` prints the globals in the order the registry announces them, each
# wl_output with a `name:` line (its connector, as niri names it). Only the
# wl_output sections count: other blocks carry `name:` lines of their own (the
# xdg_output manager lists the outputs in another order, wl_seat has `seat0`).
#
# An output announced without a name (wl_output older than version 4) is listed as
# `?`, so the ones after it keep their numbers. Anything unexpected (niri not
# answering, no output named, the pointer's output not announced) opens the plain
# `flameshot gui`, which asks which output and so cannot pick the wrong one.
focused=$(niri msg --json focused-output | jq -r '.name // empty' || true)

found=
if [ -n "$focused" ]; then
  n=0
  while read -r name; do
    if [ "$name" = "$focused" ]; then
      found=$n
      break
    fi
    n=$((n + 1))
  done < <(wayland-info | awk -v iface="'wl_output'," '
    /^interface:/ {
      if (want) print "?"
      want = ($2 == iface)
      next
    }
    want && /^[[:space:]]+name: / { print $2; want = 0 }
    END { if (want) print "?" }
  ' || true)
fi

if [ -n "$found" ]; then
  exec flameshot screen --edit -n "$found"
fi
exec flameshot gui
