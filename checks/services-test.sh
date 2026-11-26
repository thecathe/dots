#!/usr/bin/env bash
# Behaviour of the `services` command against fake services whose commands
# touch files under a throwaway directory: the listing and its JSON, states,
# up, down and toggle, the short names, extra actions (refused while the
# service is down, run in place, in a window), the timeout (a hung status is
# `unknown`, -t changes it, it bounds `up` only when given), that every service
# is checked at the same time, and the refusals. Run by checks/services.nix
# (services and jq on PATH); run by hand the same way.
set -u

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
export SVC=$root/state
mkdir -p "$SVC"

fails=0
ok() { printf 'ok    %s\n' "$1"; }
bad() {
  printf 'FAIL  %s\n' "$1"
  fails=$((fails + 1))
}
check() { # check NAME CONDITION-COMMAND...
  local name=$1
  shift
  if "$@"; then ok "$name"; else bad "$name"; fi
}
not() { ! "$@"; }
exists() { [ -e "$SVC/$1" ]; }
reset() { rm -rf "$SVC" && mkdir -p "$SVC"; }
# run ARGS...: run services, keeping its output in $out and its status in $rc
run() {
  out=$(services "$@" 2>"$root/err")
  rc=$?
  err=$(cat "$root/err")
}
rc_is() { [ "$rc" = "$1" ]; }
out_is() { [ "$out" = "$1" ]; }
field() { jq -r ".services[] | select(.id == \"$1\") | $2" <<<"$out"; }
now_ms() { date +%s%3N; }

# Every command is `sh -c` over $SVC, so one manifest serves the whole run.
#   alpha (a): up/down make and remove a file; `detail` prints a file's contents;
#              actions: shout (s, needs up), console (c, terminal), free (any time)
#   beta (b):  its status never finishes
#   gamma (g): always down; its `up` takes five seconds
#   delta (d): its status is a program that does not exist
#   echo (e):  its `up` is handed one word with a space and a newline in it
cat >"$root/manifest.json" <<'EOF'
{
  "name": "services",
  "timeout": 3,
  "window": {
    "prefix": ["sh", "-c", "printf '%s\\n' \"$@\" >\"$SVC/window\"", "stub-kitty"],
    "wrapper": "/wrapper"
  },
  "services": [
    {
      "id": "alpha", "short": "a", "label": "Alpha", "icon": "x",
      "up": ["sh", "-c", "touch \"$SVC/alpha\""],
      "down": ["sh", "-c", "rm -f \"$SVC/alpha\""],
      "status": ["sh", "-c", "test -e \"$SVC/alpha\""],
      "detail": ["sh", "-c", "cat \"$SVC/detail\" 2>/dev/null"],
      "actions": [
        {"id": "shout", "short": "s", "label": "Shout it", "icon": "i", "requiresUp": true, "terminal": false,
         "argv": ["sh", "-c", "echo shouted >\"$SVC/shout\""]},
        {"id": "console", "short": "c", "label": "Attach to console", "icon": "i", "requiresUp": false, "terminal": true,
         "argv": ["sh", "-c", "echo console >\"$SVC/console\""]},
        {"id": "free", "short": null, "label": "Free", "icon": "i", "requiresUp": false, "terminal": false,
         "argv": ["sh", "-c", "echo free >\"$SVC/free\"; exit 7"]}
      ]
    },
    {
      "id": "beta", "short": "b", "label": "Beta", "icon": "x",
      "up": ["sh", "-c", "touch \"$SVC/beta-up\""],
      "down": ["true"],
      "status": ["sh", "-c", "sleep 5"],
      "detail": null, "actions": []
    },
    {
      "id": "gamma", "short": "g", "label": "Gamma", "icon": "x",
      "up": ["sleep", "5"],
      "down": ["true"],
      "status": ["false"],
      "detail": null, "actions": []
    },
    {
      "id": "delta", "short": null, "label": "Delta", "icon": "x",
      "up": ["true"], "down": ["true"],
      "status": ["/nonexistent/program"],
      "detail": null, "actions": []
    },
    {
      "id": "echo", "short": "e", "label": "Echo", "icon": "x",
      "up": ["sh", "-c", "printf '%s' \"$1\" >\"$SVC/word\"", "sh", "a b\nc"],
      "down": ["true"],
      "status": ["false"],
      "detail": null, "actions": []
    }
  ]
}
EOF
export SERVICES_CONFIG=$root/manifest.json

# --- the listing -------------------------------------------------------------
run --json -t 0.5
check "--json is JSON" jq -e . <<<"$out" >/dev/null
check "--json lists the services in order" [ "$(jq -r '[.services[].id] | join(",")' <<<"$out")" = alpha,beta,gamma,delta,echo ]
check "--json carries the short name, label and icon" [ "$(field alpha '[.short, .label, .icon] | join("/")')" = a/Alpha/x ]
check "--json: a service with no short name has null" [ "$(field delta '.short')" = null ]
check "--json: down" [ "$(field alpha .state)" = down ]
check "--json: a hung status is unknown" [ "$(field beta .state)" = unknown ]
check "--json: a program that does not exist is unknown, not down" [ "$(field delta .state)" = unknown ]
check "--json: always-failing is down" [ "$(field gamma .state)" = down ]
check "--json lists an action's id, short name, flags and label" [ "$(field alpha '.actions[0] | [.id, .short, .requiresUp, .terminal, .label] | join("/")')" = "shout/s/true/false/Shout it" ]
check "--json leaves the commands out" not jq -e '.. | objects | select(has("argv") or has("up") or has("status"))' <<<"$out"
check "--json has the limit it ran with" [ "$(jq -r .timeout <<<"$out")" = 0.5 ]

run -t 0.5
check "the table has a header and a line per service" [ "$(wc -l <<<"$out")" = 6 ]
check "the table shows ? for unknown" [ "$(grep -c '?' <<<"$out")" = 2 ]
check "the table starts with its header" [ "$(head -n 1 <<<"$out" | tr -s ' ')" = "ID SHORT STATE DETAIL LABEL" ]
run list -t 0.5
check "list is the same as no command" rc_is 0

# --- states, up, down, toggle ------------------------------------------------
run status alpha
check "status of a down service: down, exit 3" bash -c "[ '$out' = down ] && [ $rc = 3 ]"
run up a
check "up by short name runs the command" bash -c "[ $rc = 0 ] && [ -e '$SVC/alpha' ]"
run status alpha
check "status of an up service: up, exit 0" bash -c "[ '$out' = up ] && [ $rc = 0 ]"
run status b -t 0.5
check "status of a hung service: unknown, exit 4" bash -c "[ '$out' = unknown ] && [ $rc = 4 ]"
run down alpha
check "down runs the command" bash -c "[ $rc = 0 ] && [ ! -e '$SVC/alpha' ]"
run toggle alpha
check "toggle brings a down service up" exists alpha
run toggle alpha
check "toggle takes an up service down" not exists alpha
run toggle beta -t 0.5
check "toggle refuses when the state is unknown (exit 4)" rc_is 4
check "toggle did not run anything then" not exists beta-up
run up echo
check "a word with a space and a newline arrives whole" [ "$(cat "$SVC/word")" = "$(printf 'a b\nc')" ]

# --- detail ------------------------------------------------------------------
printf 'recording\n' >"$SVC/detail"
run --json
check "detail is null while the service is down" [ "$(field alpha .detail)" = null ]
touch "$SVC/alpha"
run --json
check "detail is what the command prints while up" [ "$(field alpha .detail)" = recording ]
printf 'first\nsecond\n' >"$SVC/detail"
run --json
check "only the first line of detail" [ "$(field alpha .detail)" = first ]
printf 'x%.0s' $(seq 100) >"$SVC/detail"
run --json
check "detail is cut at 64 characters" [ "$(field alpha '.detail | length')" = 64 ]
printf '\033[31mred\033[0m\n' >"$SVC/detail"
run --json
check "control characters are dropped from detail" [ "$(field alpha .detail)" = '[31mred[0m' ]
rm -f "$SVC/detail"
run --json
check "no detail output is null" [ "$(field alpha .detail)" = null ]
run show alpha
check "show says the state and lists the actions" bash -c "echo '$out' | grep -q 'Alpha (alpha, a): up' && echo '$out' | grep -q 'shout' && echo '$out' | grep -q 'Attach to console'"
rm -f "$SVC/alpha"

# --- actions -----------------------------------------------------------------
run action alpha shout
check "an action that needs the service up is refused while it is down (exit 3)" rc_is 3
check "...and was not run" not exists shout
touch "$SVC/alpha"
run action alpha shout
check "the same action runs while it is up" bash -c "[ $rc = 0 ] && [ -e '$SVC/shout' ]"
rm -f "$SVC/shout"
run action a s
check "an action by short names" exists shout
rm -f "$SVC/alpha"
run action alpha free
check "an action that does not need the service runs while it is down" exists free
check "an action's own exit status comes back" rc_is 7
run action alpha nope
check "no such action: exit 2" rc_is 2
run action nope shout
check "no such service: exit 2" rc_is 2
run action alpha c
check "a terminal action runs in this terminal by default" exists console
check "...with no window opened" not exists window
rm -f "$SVC/console"
run action alpha console --window
check "with --window it goes to the window command, not here" not exists console
check "the window gets a title, then the wrapper, then the action" [ "$(cat "$SVC/window")" = "$(printf '%s\n' --title 'Alpha: Attach to console' /wrapper sh -c 'echo console >"$SVC/console"')" ]
rm -f "$SVC/window"
run action alpha free --window
check "--window leaves a background action alone" bash -c "[ -e '$SVC/free' ] && [ ! -e '$SVC/window' ]"

# --- the timeout -------------------------------------------------------------
start=$(now_ms)
run status beta -t 0.4
check "a hung status ends at the limit" [ $(($(now_ms) - start)) -lt 2500 ]
run status beta -t 0.4 --json
check "--json belongs to list only (exit 64)" rc_is 64
start=$(now_ms)
run up gamma -t 0.4
check "-t bounds up: exit 124" rc_is 124
check "...and it ended at the limit" [ $(($(now_ms) - start)) -lt 2500 ]
run status alpha --timeout=0
check "--timeout=0 means no limit and still answers" rc_is 3
run status alpha -t 1.5
check "decimals are accepted" rc_is 3

# --- every service is checked at the same time -------------------------------
cat >"$root/slow.json" <<'EOF'
{"name": "services", "timeout": 5, "window": null, "services": [
  {"id": "s1", "short": null, "label": "S1", "icon": "x", "up": ["true"], "down": ["true"], "status": ["sleep", "1"], "detail": null, "actions": []},
  {"id": "s2", "short": null, "label": "S2", "icon": "x", "up": ["true"], "down": ["true"], "status": ["sleep", "1"], "detail": null, "actions": []},
  {"id": "s3", "short": null, "label": "S3", "icon": "x", "up": ["true"], "down": ["true"], "status": ["sleep", "1"], "detail": null, "actions": []}
]}
EOF
start=$(now_ms)
SERVICES_CONFIG=$root/slow.json run --json
check "three one-second checks together take about one second, not three" [ $(($(now_ms) - start)) -lt 2500 ]
check "...and all three are up" [ "$(jq -r '[.services[].state] | join(",")' <<<"$out")" = up,up,up ]

# --- a machine with nothing --------------------------------------------------
echo '{"name": "services", "timeout": 3, "window": null, "services": []}' >"$root/none.json"
SERVICES_CONFIG=$root/none.json run --json
check "no services: an empty list" [ "$(jq -c .services <<<"$out")" = '[]' ]
SERVICES_CONFIG=$root/none.json run
check "no services: the header alone, exit 0" rc_is 0

# --- refusals ----------------------------------------------------------------
run status nope
check "no such service: exit 2" rc_is 2
run up
check "up without a service: usage, exit 64" rc_is 64
run action alpha
check "action without an action: exit 64" rc_is 64
run frobnicate
check "an unknown command: exit 64" rc_is 64
run --window up alpha
check "--window outside action: exit 64" rc_is 64
run status alpha -t soon
check "a timeout that is not a number: exit 64" rc_is 64
run status alpha -t
check "-t without a number: exit 64" rc_is 64
run --nonsense
check "an unknown option: exit 64" rc_is 64
SERVICES_CONFIG=$root/missing.json run
check "no manifest: exit 1" rc_is 1
run --help
check "--help prints the usage and exits 0" bash -c "[ $rc = 0 ] && echo '$out' | grep -q 'usage: services'"
echo '{"name": "svc", "timeout": 3, "window": null, "services": []}' >"$root/named.json"
SERVICES_CONFIG=$root/named.json run --help
check "the usage uses the command's configured name" bash -c "echo '$out' | grep -q 'usage: svc'"
echo '{"name": "svc", "timeout": 3, "window": null, "services": [{"id":"w","short":null,"label":"W","icon":"x","up":["true"],"down":["true"],"status":["true"],"detail":null,"actions":[{"id":"t","short":null,"label":"T","icon":"i","requiresUp":false,"terminal":true,"argv":["true"]}]}]}' >"$root/nowindow.json"
SERVICES_CONFIG=$root/nowindow.json run action w t --window
check "--window with no terminal configured: exit 1" rc_is 1

echo
if [ "$fails" -ne 0 ]; then
  echo "$fails check(s) failed" >&2
  exit 1
fi
echo "all checks passed"
