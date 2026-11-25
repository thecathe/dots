#!/usr/bin/env bash
# Behaviour of flameshot-screen (modules/home/flameshot/screen.sh) against stand-ins for
# niri, wayland-info and flameshot (checks/flameshot-screen-stubs.sh): which screen
# number it hands Flameshot for the output the pointer is on, with the outputs
# announced in either order (the bug: the AOC announced before the Dell, after the
# Dell had been switched off and on, while the module assumed the Dell first), a block
# with a `name:` line of its own that is not an output, an output announced without a
# name, and every way the answer can be missing (the fallback is the plain `gui`,
# which asks, and so cannot pick the wrong output). Run by checks/flameshot-screen.nix
# (flameshot-screen on PATH); run by hand the same way, from this directory.
set -u

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
export STUB_DIR=$root/stub
here=$(dirname "${BASH_SOURCE[0]}")

fails=0
ok() { printf 'ok    %s\n' "$1"; }
bad() {
  printf 'FAIL  %s\n' "$1"
  fails=$((fails + 1))
}

# What `wayland-info` prints for the outputs named in the arguments, announced in that
# order. A `?` stands for an output older than wl_output version 4, which has no name.
# The blocks around them carry `name:` lines too, as the real tool's output does
# (checks/flameshot-screen-wayland-info.txt is a real one): the xdg_output manager
# lists HDMI-A-1 and DP-1 in one fixed order, and wl_seat is called seat0.
announce() {
  cat <<'EOF'
interface: 'wl_compositor',                              version:  6, name:  1
interface: 'zxdg_output_manager_v1',                     version:  3, name:  9
	xdg_output_v1
		output: 48
		name: 'HDMI-A-1'
		logical_x: 0, logical_y: 0
	xdg_output_v1
		output: 47
		name: 'DP-1'
		logical_x: 1080, logical_y: 0
interface: 'wl_seat',                                    version:  9, name: 40
	name: seat0
	capabilities: pointer keyboard
EOF
  local id=47 o
  for o in "$@"; do
    if [ "$o" = '?' ]; then
      printf "interface: 'wl_output',                                  version:  3, name: %s\n" "$id"
    else
      printf "interface: 'wl_output',                                  version:  4, name: %s\n\tname: %s\n" "$id" "$o"
    fi
    printf '\tx: 0, y: 0, scale: 1,\n\tmake: '\''Some Maker'\'', model: '\''Some Model'\'',\n\tmode:\n\t\twidth: 1920 px, height: 1080 px, refresh: 60.000 Hz,\n\t\tflags: current preferred\n'
    id=$((id + 1))
  done
  echo "interface: 'wp_cursor_shape_manager_v1',                 version:  2, name: 99"
}

# run NAME POINTER-OUTPUT EXPECTED COMMAND...
# COMMAND prints what `wayland-info` prints; nothing printed means it fails. POINTER-OUTPUT
# is what niri reports as focused: `none` for no focused output in its answer, `down` for
# niri not answering at all. EXPECTED is the whole argument list of the one `flameshot`
# run. Never called in a pipeline: that would be a subshell, and a failure counted in it
# would be lost.
run() {
  local name=$1 pointer=$2 expect=$3 got
  shift 3
  rm -rf "$STUB_DIR"
  mkdir -p "$STUB_DIR"
  if [ "$pointer" = down ]; then touch "$STUB_DIR/niri-down"; elif [ "$pointer" != none ]; then echo "$pointer" >"$STUB_DIR/focused"; fi
  "$@" >"$STUB_DIR/wayland-info.txt"
  [ -s "$STUB_DIR/wayland-info.txt" ] || rm "$STUB_DIR/wayland-info.txt"
  flameshot-screen >/dev/null 2>&1
  got=$(cat "$STUB_DIR/flameshot.log" 2>/dev/null || true)
  if [ "$got" = "$expect" ]; then ok "$name"; else bad "$name: flameshot ran with [$got], wanted [$expect]"; fi
}

# The state that went wrong on 2026-11-25: the real capture, DP-1 announced first.
run "real capture, pointer on HDMI-A-1 (announced second)" HDMI-A-1 "screen --edit -n 1" cat "$here/flameshot-screen-wayland-info.txt"
run "real capture, pointer on DP-1 (announced first)" DP-1 "screen --edit -n 0" cat "$here/flameshot-screen-wayland-info.txt"

# Both orders the same two outputs can be announced in.
run "Dell announced first, pointer on HDMI-A-1" HDMI-A-1 "screen --edit -n 0" announce HDMI-A-1 DP-1
run "Dell announced first, pointer on DP-1" DP-1 "screen --edit -n 1" announce HDMI-A-1 DP-1
run "AOC announced first, pointer on HDMI-A-1" HDMI-A-1 "screen --edit -n 1" announce DP-1 HDMI-A-1
run "AOC announced first, pointer on DP-1" DP-1 "screen --edit -n 0" announce DP-1 HDMI-A-1

run "one output" DP-1 "screen --edit -n 0" announce DP-1
run "three outputs, pointer on the last" DP-3 "screen --edit -n 2" announce eDP-1 HDMI-A-1 DP-3
run "three outputs, pointer on the middle one" HDMI-A-1 "screen --edit -n 1" announce eDP-1 HDMI-A-1 DP-3

# Unnamed outputs still take their place in the numbering.
run "an unnamed output announced before the pointer's" DP-1 "screen --edit -n 1" announce '?' DP-1
run "an unnamed output announced after the pointer's" DP-1 "screen --edit -n 0" announce DP-1 '?'
run "only an unnamed output" DP-1 "gui" announce '?'

# What is not an answer: ask rather than guess.
run "pointer's output is not announced (only in the xdg_output block)" HDMI-A-1 "gui" announce DP-1
run "pointer's output is the seat's name, not an output" seat0 "gui" announce DP-1 HDMI-A-1
run "niri does not answer" down "gui" announce DP-1 HDMI-A-1
run "niri names no focused output" none "gui" announce DP-1 HDMI-A-1
run "wayland-info fails" DP-1 "gui" true
run "wayland-info prints something else" DP-1 "gui" echo "this is not what wayland-info prints"
run "no output announced" DP-1 "gui" announce

if [ "$fails" -ne 0 ]; then
  echo "$fails failed" >&2
  exit 1
fi
