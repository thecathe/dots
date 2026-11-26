#!/usr/bin/env bash
# services: the dots.services entries of this machine (Immich, Tailscale, a game
# server, a VPN, ...) at a glance, switched on and off by hand, with the extra
# actions the DMS services menu offers. The menu (modules/home/dank, plugins/
# dotsServices) shows the same entries; this is the same thing for a terminal.
#
#   services [list]                  one line per service: id, short name, state, detail, label
#   services --json                  the same as JSON ({generated, timeout, services: [...]})
#   services show ID                 one service: its state and its actions
#   services status ID               print up, down or unknown; exit 0, 3 or 4
#   services up ID                   run the service's up command
#   services down ID                 run its down command
#   services toggle ID               down if it is up, up if it is down
#   services action ID ACTION        run one of its extra actions
#
# ID is a service's id or its short name, ACTION an action's id or short name.
# Both are set in Nix (dots.services.<name>.id/.short and the same on an action),
# as are this command's own name and the default limit below.
#
#   -t, --timeout SECONDS   how long each status check (and `detail`) may take; a
#                           check that overruns is reported as `unknown`. 0 means
#                           no limit. Decimals are fine (1.5). It bounds `up`,
#                           `down` and an action only when given here.
#   --window                for `action`: a terminal action (an interactive one,
#                           such as an attach) opens in its own terminal window,
#                           as the menu does, instead of running in this one.
#   --json                  for `list`: JSON.
#
# A service is up when its status command exits 0; down when it exits with
# anything from 1 to 123; unknown when it cannot be run or does not finish in
# time (exit 124 and up: the limit, a missing program, a signal). All services
# are checked at once, so listing them takes as long as the slowest. `detail`
# is only asked of a service that is up.
#
# Exit codes: 0 done (or up); 2 no such service or action; 3 down (status), or
# an action that needs the service up refused because it is down; 4 unknown;
# 64 bad usage. `up`, `down`, `toggle` and `action` otherwise end with the
# command's own exit status (124 when -t stopped it), so those codes can also be
# the command's.
#
# Configuration: SERVICES_CONFIG names a JSON file {name, timeout, window,
# services}, written by package.nix from the dots.services entries; without it,
# the file the package was built with (SERVICES_DEFAULT_CONFIG).

# writeShellApplication turns errexit and pipefail on; this script looks at
# every status itself (a command failing is the answer, not an error), so off.
set +o errexit +o pipefail
set -u

config=${SERVICES_CONFIG:-${SERVICES_DEFAULT_CONFIG:-}}
if [ -z "$config" ] || [ ! -r "$config" ]; then
  echo "services: no configuration (SERVICES_CONFIG names none)" >&2
  exit 1
fi
prog=$(jq -r '.name // "services"' "$config")
default_timeout=$(jq -r '.timeout // 3' "$config")

usage_text() {
  cat <<EOF
usage: $prog [list]                  one line per service: id, short name, state, detail, label
       $prog --json                  the same as JSON
       $prog show ID                 one service: its state and its actions
       $prog status ID               print up, down or unknown (exit 0, 3 or 4)
       $prog up ID                   bring the service up
       $prog down ID                 take it down
       $prog toggle ID               down if it is up, up if it is down
       $prog action ID ACTION        run one of its extra actions

options: -t, --timeout SECONDS  how long a status check may take (default $default_timeout; 0 for no limit);
                                it bounds up, down and actions only when given
         --window               open a terminal action in its own window instead of this terminal
         -h, --help             this text
EOF
}
usage() {
  usage_text >&2
  exit 64
}
die() { # die STATUS MESSAGE
  local status=$1
  shift
  echo "$prog: $*" >&2
  exit "$status"
}

want_json=0
want_window=0
timeout_given=""
pos=()
while [ $# -gt 0 ]; do
  case $1 in
    -h | --help)
      usage_text
      exit 0
      ;;
    --json) want_json=1 ;;
    --window) want_window=1 ;;
    -t | --timeout)
      [ $# -ge 2 ] || die 64 "$1 needs a number of seconds"
      timeout_given=$2
      shift
      ;;
    --timeout=*) timeout_given=${1#--timeout=} ;;
    --)
      shift
      pos+=("$@")
      break
      ;;
    -*) die 64 "unknown option $1 (see --help)" ;;
    *) pos+=("$1") ;;
  esac
  shift
done

if [ -n "$timeout_given" ] && ! [[ $timeout_given =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  die 64 "the timeout is a number of seconds, not '$timeout_given'"
fi
limit=${timeout_given:-$default_timeout}

# run_limited SECONDS COMMAND...: the command, killed (after a second's grace)
# when it overruns; 0 means no limit. Its own process group, so a status script's
# children go with it. Not for anything interactive: see exec_command.
run_limited() {
  local limit=$1
  shift
  if [ "$limit" = 0 ]; then
    "$@"
  else
    timeout -k 1 "$limit" "$@"
  fi
}

# argv_of JSON PATH: the array at PATH in JSON, each word read back whole (they
# may hold any character, so they travel NUL-separated), into the array `words`.
argv_of() {
  local word
  words=()
  while IFS= read -r -d '' word; do
    words+=("$word")
  done < <(jq -j "$2 | .[] | (., \"\\u0000\")" <<<"$1")
}

# find_service KEY: the JSON of the service whose id or short name is KEY.
find_service() {
  local found
  found=$(jq -c --arg k "$1" '[.services[] | select(.id == $k or .short == $k)] | first // empty' "$config")
  if [ -z "$found" ]; then
    echo "$prog: no service '$1' (see: $prog list)" >&2
    return 1
  fi
  printf '%s\n' "$found"
}

# get_state SERVICE-JSON: up, down or unknown (see the top).
get_state() {
  local rc
  argv_of "$1" .status
  run_limited "$limit" "${words[@]}" >/dev/null 2>&1 </dev/null
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echo up
  elif [ "$rc" -ge 124 ]; then
    echo unknown
  else
    echo down
  fi
}

# get_detail SERVICE-JSON: the first line `detail` prints, without control
# characters and cut at 64; nothing when there is none.
get_detail() {
  if [ "$(jq -r '.detail != null' <<<"$1")" != true ]; then
    return 0
  fi
  argv_of "$1" .detail
  run_limited "$limit" "${words[@]}" 2>/dev/null </dev/null | head -n 1 | tr -d '[:cntrl:]' | cut -c1-64
}

# exec_command WORD...: become the command, in this terminal. Only under -t does
# it go through timeout, which then must not take the terminal away from it
# (--foreground), or an attach would be stopped for reading from it.
exec_command() {
  if [ -n "$timeout_given" ] && [ "$timeout_given" != 0 ]; then
    exec timeout --foreground -k 1 "$timeout_given" "$@"
  fi
  exec "$@"
}

# every_service_json: {generated, timeout, services: [...]} with every state, all
# checked at the same time. The commands and their arguments stay out of it.
every_service_json() {
  local tmp count i files=()
  tmp=$(mktemp -d)
  count=$(jq '.services | length' "$config")
  for ((i = 0; i < count; i++)); do
    (
      svc=$(jq -c ".services[$i]" "$config")
      state=$(get_state "$svc")
      detail=""
      if [ "$state" = up ]; then
        detail=$(get_detail "$svc")
      fi
      jq -n --arg state "$state" --arg detail "$detail" \
        '{state: $state, detail: (if $detail == "" then null else $detail end)}' >"$tmp/$i.json"
    ) &
    files+=("$tmp/$i.json")
  done
  wait
  jq -s --argjson timeout "$limit" '
    .[0] as $manifest
    | .[1:] as $checked
    | {
        generated: (now | floor),
        timeout: $timeout,
        services: [
          $manifest.services | to_entries[]
          | .key as $i
          | .value
          | {id, short, label, icon,
             state: $checked[$i].state,
             detail: $checked[$i].detail,
             actions: [.actions[] | {id, short, label, icon, requiresUp, terminal}]}
        ]
      }' "$config" "${files[@]}"
  rm -rf "$tmp"
}

# A table of the services in the JSON on stdin.
print_services() {
  {
    printf 'ID\tSHORT\tSTATE\tDETAIL\tLABEL\n'
    jq -r '.services[] | [.id, (.short // "-"), (if .state == "unknown" then "?" else .state end), (.detail // "-"), .label] | @tsv'
  } | column -t -s $'\t'
}

cmd=${pos[0]:-list}
if [ "$want_window" = 1 ] && [ "$cmd" != action ]; then
  die 64 "--window is for 'action'"
fi
if [ "$want_json" = 1 ] && [ "$cmd" != list ]; then
  die 64 "--json is for 'list'"
fi

case $cmd in
  list)
    [ "${#pos[@]}" -le 1 ] || usage
    if [ "$want_json" = 1 ]; then
      every_service_json
    else
      every_service_json | print_services
    fi
    ;;

  show | status | up | down | toggle)
    [ "${#pos[@]}" -eq 2 ] || usage
    svc=$(find_service "${pos[1]}") || exit 2
    case $cmd in
      status)
        state=$(get_state "$svc")
        echo "$state"
        case $state in
          up) exit 0 ;;
          down) exit 3 ;;
          *) exit 4 ;;
        esac
        ;;
      up | down)
        argv_of "$svc" ".$cmd"
        exec_command "${words[@]}"
        ;;
      toggle)
        state=$(get_state "$svc")
        case $state in
          up) argv_of "$svc" .down ;;
          down) argv_of "$svc" .up ;;
          *) die 4 "$(jq -r .label <<<"$svc") could not be checked in time, so it is not switched (try a longer --timeout)" ;;
        esac
        exec_command "${words[@]}"
        ;;
      show)
        state=$(get_state "$svc")
        detail=""
        if [ "$state" = up ]; then
          detail=$(get_detail "$svc")
        fi
        jq -r --arg state "$state" --arg detail "$detail" '
          "\(.label) (\(.id)\(if .short then ", " + .short else "" end)): \($state)\(if $detail != "" then ", " + $detail else "" end)"' <<<"$svc"
        if [ "$(jq '.actions | length' <<<"$svc")" -gt 0 ]; then
          {
            printf 'ACTION\tSHORT\tNEEDS UP\tWINDOW\tLABEL\n'
            jq -r '.actions[] | [.id, (.short // "-"), (if .requiresUp then "yes" else "-" end), (if .terminal then "yes" else "-" end), .label] | @tsv' <<<"$svc"
          } | column -t -s $'\t'
        fi
        ;;
    esac
    ;;

  action)
    [ "${#pos[@]}" -eq 3 ] || usage
    svc=$(find_service "${pos[1]}") || exit 2
    act=$(jq -c --arg k "${pos[2]}" '[.actions[] | select(.id == $k or .short == $k)] | first // empty' <<<"$svc")
    if [ -z "$act" ]; then
      die 2 "$(jq -r .label <<<"$svc") has no action '${pos[2]}' (see: $prog show ${pos[1]})"
    fi
    label=$(jq -r .label <<<"$svc")
    if [ "$(jq -r .requiresUp <<<"$act")" = true ]; then
      case $(get_state "$svc") in
        up) ;;
        down) die 3 "$(jq -r .label <<<"$act") needs $label up, and it is down" ;;
        *) die 4 "$label could not be checked in time, so '$(jq -r .label <<<"$act")' was not run (try a longer --timeout)" ;;
      esac
    fi
    argv_of "$act" .argv
    if [ "$want_window" = 1 ] && [ "$(jq -r .terminal <<<"$act")" = true ]; then
      if [ "$(jq -r '.window != null' "$config")" != true ]; then
        die 1 "no terminal is configured for --window"
      fi
      action_words=("${words[@]}")
      argv_of "$(jq -c .window "$config")" .prefix
      prefix=("${words[@]}")
      wrapper=$(jq -r .window.wrapper "$config")
      # The title is what the menu has always shown: "<service>: <action>".
      exec "${prefix[@]}" --title "$label: $(jq -r .label <<<"$act")" "$wrapper" "${action_words[@]}"
    fi
    exec_command "${words[@]}"
    ;;

  *) usage ;;
esac
