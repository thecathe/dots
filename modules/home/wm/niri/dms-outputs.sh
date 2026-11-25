# niri-dms-outputs [--dry-run] [FILE]
#
# At login, turns off the outputs that DMS has marked `off` in its generated
# ~/.config/niri/dms/outputs.kdl (or in FILE), so that the display profile DMS
# shows as active is the one that is actually in force.
#
# Why: niri uses the first `output` block that matches a name and never merges
# them, and a host's own block for the same output (the portrait monitor's
# 100% default column width, in the `nixos` host) comes before the DMS file.
# So the `off` DMS wrote for a profile such as "1 Screen" is read and ignored,
# and the monitor comes up at every login while DMS says the profile is applied.
# Applying the profile by hand worked only because DMS also runs
# `niri msg output NAME off` at that moment; this script does the same, once, at
# login. DMS applies no profile at startup by itself (its auto-select is off by
# default), and it need not be running for this to work.
#
# What it does and does not do:
#   - only outputs that are `off` at the top level of their block, as DMS's own
#     parser reads it; an `off` nested deeper, or in a comment, is not one;
#   - an output is named as DMS wrote it: its connector name ("HDMI-A-1") or
#     niri's "make model serial" form; one that is not connected is left alone;
#   - it waits (NIRI_DMS_OUTPUTS_TRIES attempts, a quarter second apart; 80 by
#     default) for niri to answer and for the outputs to appear, since this runs
#     from `spawn-at-startup` while the compositor is still bringing them up;
#   - it never turns off the last output that is on;
#   - it only ever turns outputs OFF. Turning one on, or any other change in the
#     profile, is DMS's job when the profile is applied from its settings.
#
# The change is niri's temporary kind: a later reload of the config keeps it as
# long as the `output` blocks of the config files are unchanged (the DMS files
# for colours, layout and so on do not count), and forgets it when they change,
# such as after a rebuild that edits a host's output block, or when DMS rewrites
# outputs.kdl differently. DMS's own apply re-issues its live changes after such
# a reload; after a rebuild, run this again or re-apply the profile.
#
# --dry-run only says what would be turned off.

say() { echo "niri-dms-outputs: $*" >&2; }
usage() { echo "usage: niri-dms-outputs [--dry-run] [FILE]" >&2; }

dry=0
file=""
for arg in "$@"; do
  case "$arg" in
  --dry-run | -n) dry=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    usage
    exit 2
    ;;
  *) file=$arg ;;
  esac
done
file="${file:-${XDG_CONFIG_HOME:-$HOME/.config}/niri/dms/outputs.kdl}"

[ -f "$file" ] || exit 0

# The outputs whose block holds `off` at its top level. Braces are counted to
# know the depth; `//` comments are cut first.
off_outputs() {
  awk '
    {
      line = $0
      sub(/\/\/.*/, "", line)
      if (depth == 0 && line ~ /^[ \t]*output[ \t]+"[^"]*"[ \t]*[{]/) {
        name = line
        sub(/^[ \t]*output[ \t]+"/, "", name)
        sub(/".*/, "", name)
        current = name
      } else if (depth == 1 && current != "" && line ~ /^[ \t]*off[ \t]*;?[ \t]*$/) {
        print current
        current = ""
      }
      depth += gsub(/[{]/, "{", line) - gsub(/[}]/, "}", line)
      if (depth <= 0) {
        depth = 0
        current = ""
      }
    }
  ' "$file"
}

mapfile -t wanted < <(off_outputs)
[ "${#wanted[@]}" -gt 0 ] || exit 0

json=""
# The connector name of the output that NAME (a connector or "make model
# serial", as in niri's config) refers to, or nothing.
resolve() {
  jq -r --arg n "$1" '
    [to_entries[]
     | select(.key == $n
              or "\(.value.make // "Unknown") \(.value.model // "Unknown") \(.value.serial // "Unknown")" == $n)
     | .key]
    | first // empty' <<<"$json"
}

tries="${NIRI_DMS_OUTPUTS_TRIES:-80}"
attempt=0
while :; do
  if json=$(niri msg --json outputs 2>/dev/null); then
    all_here=1
    for name in "${wanted[@]}"; do
      [ -n "$(resolve "$name")" ] || all_here=0
    done
    [ "$all_here" = 1 ] && break
  fi
  attempt=$((attempt + 1))
  [ "$attempt" -lt "$tries" ] || break
  sleep 0.25
done

if [ -z "$json" ]; then
  say "niri did not answer, nothing changed"
  exit 1
fi

status=0
on=$(jq '[.[] | select(.logical != null)] | length' <<<"$json")
for name in "${wanted[@]}"; do
  connector=$(resolve "$name")
  if [ -z "$connector" ]; then
    say "$name is not connected, left alone"
    continue
  fi
  if [ "$(jq -r --arg c "$connector" '.[$c].logical == null' <<<"$json")" = true ]; then
    say "$connector is already off"
    continue
  fi
  if [ "$on" -le 1 ]; then
    say "$connector is the only output that is on, not turning it off"
    continue
  fi
  if [ "$dry" = 1 ]; then
    say "would turn off $connector"
    on=$((on - 1))
  elif niri msg output "$connector" off; then
    say "turned off $connector (marked off by DMS)"
    on=$((on - 1))
  else
    say "could not turn off $connector"
    status=1
  fi
done
exit "$status"
