#!/usr/bin/env bash
# Behaviour of check-each (tools/check-each/check-each.sh) against stand-ins for `nix` and
# `systemd-run`, so nothing real is evaluated, built or limited: that every check runs in
# its own capped process and strictly after the previous one, that a failing check does
# not stop the rest, that a check killed at the ceiling is reported as NOT RUN (its own
# exit status, neither a pass nor a failure), that a missing or unusable systemd-run is
# an error and never a silent uncapped run, the options, and the outputs step. Run by
# checks/check-each.nix (check-each, jq and coreutils on PATH); run by hand the same way.
#
# Cases are never run in a pipeline: a counter changed in a subshell is lost, and a test
# that cannot fail is worth nothing (that happened to flameshot-screen-test.sh).
set -u

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
export STUB_DIR=$root/stub
export TMPDIR=$root/tmp
mkdir -p "$root/bin" "$root/bin-nosd" "$TMPDIR"

fails=0
ok() { printf 'ok    %s\n' "$1"; }
bad() {
  printf 'FAIL  %s\n' "$1"
  fails=$((fails + 1))
  # What check-each last printed, so that a failure explains itself.
  if [ -n "${text:-}" ]; then sed 's/^/        | /' <<<"$text"; fi
}
check() { # check NAME COMMAND...
  local name=$1
  shift
  if "$@"; then ok "$name"; else bad "$name"; fi
}

# The stand-in nix. Its behaviour for one check is the content of $STUB_DIR/check-NAME
# (fail, kill, missing; default: passes), for one output of out-OUTPUT (fail, missing).
cat >"$root/bin/nix" <<'EOF'
#!/usr/bin/env bash
dir=${STUB_DIR:?}
echo "$*" >>"$dir/nix.log"
case $1 in
eval)
  if [ "$2" = --impure ]; then printf x86_64-linux; exit 0; fi
  attr=${3#*#}
  case $attr in
  checks.*)
    if [ -e "$dir/list-fails" ]; then echo "error: cannot list the checks" >&2; exit 1; fi
    cat "$dir/checks.json"
    exit 0
    ;;
  *)
    mode=$(cat "$dir/out-${attr%%.*}" 2>/dev/null || echo ok)
    case $mode in
    missing) echo "error: flake '.' does not provide attribute '$attr'" >&2; exit 1 ;;
    fail) echo "error: boom in $attr" >&2; exit 1 ;;
    *) echo '{}'; exit 0 ;;
    esac
    ;;
  esac
  ;;
build)
  attr=${2#*#}
  name=${attr#checks.*.}
  echo "start $name" >>"$dir/events.log"
  sleep 0.05
  echo "end $name" >>"$dir/events.log"
  case $(cat "$dir/check-$name" 2>/dev/null || echo ok) in
  fail) echo "assertion failed in $name" >&2; exit 1 ;;
  missing) echo "error: flake '.' does not provide attribute '$attr'" >&2; exit 1 ;;
  kill) exit 137 ;;
  *) exit 0 ;;
  esac
  ;;
esac
echo "nix stub: unexpected call: $*" >&2
exit 3
EOF
# The stand-in systemd-run: records what it was asked, then runs the command.
cat >"$root/bin/systemd-run" <<'EOF'
#!/usr/bin/env bash
dir=${STUB_DIR:?}
if [ -e "$dir/scope-broken" ]; then echo "Failed to connect to bus" >&2; exit 1; fi
echo "$*" >>"$dir/systemd-run.log"
while [ $# -gt 0 ]; do
  case $1 in
  --user | --scope | --quiet) shift ;;
  -p) shift 2 ;;
  *) break ;;
  esac
done
exec "$@"
EOF
# The build sandbox has no /usr/bin/env: the stand-ins run under the bash running this.
sed -i "1s|.*|#!$(command -v bash)|" "$root/bin/nix" "$root/bin/systemd-run"
chmod +x "$root/bin/nix" "$root/bin/systemd-run"
cp "$root/bin/nix" "$root/bin-nosd/nix"

setup() { # setup CHECK...: a fresh stub directory whose flake has these checks
  rm -rf "$STUB_DIR"
  mkdir -p "$STUB_DIR"
  printf '%s\n' "$@" | jq -R . | jq -s . >"$STUB_DIR/checks.json"
}
behave() { echo "$2" >"$STUB_DIR/check-$1"; }
output() { echo "$2" >"$STUB_DIR/out-$1"; }
ce=$(command -v check-each)
go() { # go ARGS...: run check-each; sets rc and text
  rc=0
  text=$(PATH=$root/bin:$PATH "$ce" "$@" 2>&1) || rc=$?
}
go_without_systemd_run() {
  rc=0
  text=$(PATH=$root/bin-nosd "$ce" "$@" 2>&1) || rc=$?
}
said() { grep -qE -- "$1" <<<"$text"; }
log() { cat "$STUB_DIR/$1" 2>/dev/null; }
builds() { log nix.log | grep -c '^build'; }
order() { log events.log | awk '{print $2}' | uniq | paste -sd, -; }
shape() { log events.log | awk '{print $1}' | paste -sd, -; }

# 1. Everything passes: one process per check, strictly one after another, in order,
#    each through systemd-run with the ceiling and no swap, each with one job.
setup a b c
go --no-outputs
check "all pass: exit 0" test "$rc" -eq 0
check "all pass: one ok line each" test "$(grep -cE '^ok +[abc] ' <<<"$text")" -eq 3
check "all pass: summary" said '3 passed, 0 failed, 0 not run'
check "one process per check, in order" test "$(order)" = a,b,c
check "strictly in series: each ends before the next starts" test "$(shape)" = start,end,start,end,start,end
check "every nix call went through systemd-run with the ceiling and no swap" test "$(log systemd-run.log | grep -c 'MemoryMax=6G -p MemorySwapMax=0 nice -n 10')" -eq "$(log systemd-run.log | wc -l)"
check "the three builds were among the capped calls" test "$(log systemd-run.log | grep -c 'nix build')" -eq 3
check "each build: no link, one job, two cores" test "$(log nix.log | grep '^build' | grep -c -- '--no-link --max-jobs 1 --cores 2')" -eq 3
check "the header names the ceiling" said 'capped at 6G'
check "logs of a clean run are removed" test -z "$(ls -A "$TMPDIR")"

# 2. A failure does not stop the rest, shows its log, and is exit 1.
setup a b c
behave b fail
go --no-outputs
check "fail: exit 1" test "$rc" -eq 1
check "fail: reported" said '^FAIL +b '
check "fail: its log is shown" said 'assertion failed in b'
check "fail: the checks after it still ran" test "$(order)" = a,b,c
check "fail: summary" said '2 passed, 1 failed, 0 not run'
check "fail: logs are kept" test -n "$(ls -A "$TMPDIR")"
rm -rf "${TMPDIR:?}"/*

# 3. Killed at the ceiling: not run, not a pass, not a failure, its own exit status.
setup a b c
behave b kill
go --no-outputs
check "killed: exit 3" test "$rc" -eq 3
check "killed: reported as not run" said '^KILLED +b .*NOT RUN'
check "killed: not counted as passed" said '2 passed, 0 failed, 1 not run'
check "killed: the checks after it still ran" test "$(order)" = a,b,c
check "killed: named in the summary" said 'not run: b'

# 4. A failure outranks a kill.
setup a b c
behave a fail
behave b kill
go --no-outputs
check "fail and kill: exit 1" test "$rc" -eq 1

# 5. Options.
setup a b c
go --no-outputs --cap 3G
check "--cap 3G is applied, not 6G" test "$(log systemd-run.log | grep -c 'MemoryMax=3G')" -eq "$(log systemd-run.log | wc -l)"
go --no-outputs --cores 4
check "--cores 4 reaches nix build" test "$(log nix.log | grep '^build' | grep -c -- '--cores 4')" -eq 3
setup a b c
go --no-outputs --no-cap
check "--no-cap: exit 0, builds ran" test "$rc" -eq 0 -a "$(builds)" -eq 3
check "--no-cap: systemd-run was not used" test ! -e "$STUB_DIR/systemd-run.log"
check "--no-cap: the header says so" said 'capped at no limit'
setup a b c
go --no-outputs --skip b
check "--skip leaves a check out" test "$(order)" = a,c
setup a b c
go --no-outputs a c
check "naming checks runs only those" test "$(order)" = a,c
setup a b c
go --no-outputs --list
check "--list prints the checks and builds nothing" test "$rc" -eq 0 -a "$(builds)" -eq 0 -a "$(grep -cE '^[abc]$' <<<"$text")" -eq 3

# 6. Setup problems are exit 2 and run nothing.
setup a b c
go --no-outputs nope
check "an unknown check name is refused" test "$rc" -eq 2 -a "$(builds)" -eq 0
check "...and named" said 'no check called nope'
go --no-outputs --skip nope
check "an unknown --skip name is refused too" test "$rc" -eq 2 -a "$(builds)" -eq 0
touch "$STUB_DIR/list-fails"
go --no-outputs
check "a failing list is exit 2" test "$rc" -eq 2 -a "$(builds)" -eq 0
check "...and says why" said 'cannot list the checks'
setup a b c
go_without_systemd_run --no-outputs
check "no systemd-run: refused, never silently uncapped" test "$rc" -eq 2 -a ! -e "$STUB_DIR/nix.log"
check "...and says to use --no-cap" said -- '--no-cap'
touch "$STUB_DIR/scope-broken"
go --no-outputs
check "a scope that cannot start: refused" test "$rc" -eq 2 -a "$(builds)" -eq 0
check "...and says why" said 'could not start a memory-capped scope'

# 7. A check that is missing an attribute fails (only the outputs step skips what the flake lacks).
setup a b c
behave b missing
go --no-outputs
check "a check that does not provide an attribute is a failure, not a skip: exit 1" test "$rc" -eq 1
check "...reported as FAIL, not skip" said '^FAIL +b '

# 8. The outputs step.
setup a b
go
check "outputs: evaluated after the checks" test "$(grep -cE '^ok +output:' <<<"$text")" -eq 8
go a
check "outputs: not run when checks are named" test "$(grep -c 'output:' <<<"$text")" -eq 0
setup a b
output devShells missing
go
check "outputs: one the flake does not have is skipped, not failed" test "$rc" -eq 0
check "outputs: ...and shown as skipped" said '^skip +output:devShells'
setup a b
output apps fail
go
check "outputs: a failing output fails the run" test "$rc" -eq 1
check "outputs: ...with its error" said 'boom in apps'
setup a b
go --no-outputs
check "--no-outputs evaluates none" test "$(log nix.log | grep -c '^eval --json .*#\(homeModules\|packages\)')" -eq 0

# 9. --logs keeps the logs of a clean run.
setup a b c
go --no-outputs --logs "$root/kept"
check "--logs keeps every step's log" test -s "$root/kept/list.json" -a -e "$root/kept/a.log" -a -e "$root/kept/c.log"

if [ "$fails" -ne 0 ]; then
  echo "$fails failed" >&2
  exit 1
fi
