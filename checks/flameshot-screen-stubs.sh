# Stand-ins for the three programs flameshot-screen runs, for checks/flameshot-screen.nix.
# One file, installed three times under different names; what to be is read from $0.
# State lives in the directory $STUB_DIR:
#   focused          the name `niri msg --json focused-output` reports (absent: it answers `null`)
#   niri-down        if present, `niri msg` fails
#   wayland-info.txt what `wayland-info` prints (absent: it fails)
#   flameshot.log    one line per `flameshot` run: its arguments
dir=${STUB_DIR:?STUB_DIR is not set}

case "$(basename "$0")" in
niri)
  [ ! -e "$dir/niri-down" ] || exit 1
  if [ "$1 $2 $3" != "msg --json focused-output" ]; then
    echo "niri stub: unexpected call: $*" >&2
    exit 3
  fi
  if [ -e "$dir/focused" ]; then
    printf '{"name": "%s", "logical": {"x": 0}}\n' "$(cat "$dir/focused")"
  else
    echo null
  fi
  ;;
wayland-info)
  [ -e "$dir/wayland-info.txt" ] || exit 1
  cat "$dir/wayland-info.txt"
  ;;
flameshot)
  echo "$*" >>"$dir/flameshot.log"
  ;;
esac
