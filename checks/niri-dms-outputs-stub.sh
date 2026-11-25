# A stand-in `niri` for checks/niri-dms-outputs.nix, installed as `niri` ahead of
# the real one. State lives in the directory $STUB_DIR:
#   outputs.json   what `niri msg --json outputs` prints (output name -> object;
#                  `logical` is null for an output that is off, as in niri)
#   answer-after   how many `msg --json outputs` calls fail before one answers (default 0)
#   fail-off       if present, `msg output NAME off` fails
#   off.log        one line per `msg output NAME off` that was run
dir=${STUB_DIR:?STUB_DIR is not set}

case "$1 $2 ${4:-}" in
"msg --json ")
  n=$(cat "$dir/count" 2>/dev/null || echo 0)
  echo $((n + 1)) >"$dir/count"
  [ "$n" -ge "$(cat "$dir/answer-after" 2>/dev/null || echo 0)" ] || exit 1
  cat "$dir/outputs.json"
  ;;
"msg output off")
  [ ! -e "$dir/fail-off" ] || exit 1
  echo "$3" >>"$dir/off.log"
  jq --arg n "$3" '.[$n].logical = null' "$dir/outputs.json" >"$dir/outputs.tmp"
  mv "$dir/outputs.tmp" "$dir/outputs.json"
  ;;
*)
  echo "niri stub: unexpected call: $*" >&2
  exit 3
  ;;
esac
