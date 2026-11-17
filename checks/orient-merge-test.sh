#!/usr/bin/env bash
# merge-hooks.jq against hand-written Claude Code settings: the hook is swapped
# and the one permission rule added and removed again, with everything the
# author keeps in that file left exactly as it was. Run by checks/orient.nix
# (jq on PATH, MERGE_JQ the filter).
set -u

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

rule='Bash(orient push-workbench)'
hook_on='{"SessionStart":[{"matcher":"startup|resume","hooks":[{"type":"command","command":"/nix/store/x-orient/bin/orient --hook # dots:managed","timeout":60}]}]}'
# merge SETTINGS MANAGED ALLOW: the filter as the module calls it
merge() { jq --argjson managed "$2" --argjson allow "$3" --argjson allowKnown "[\"$rule\"]" -f "$MERGE_JQ" <<<"$1"; }

# What the live file looked like before this change: dlsync's hook, the author's
# own settings, no permission rules.
old='{"includeCoAuthoredBy":true,"permissions":{"defaultMode":"plan"},"model":"sonnet","hooks":{"SessionStart":[{"matcher":"startup|resume","hooks":[{"type":"command","command":"/nix/store/y-dlsync/bin/dlsync --quiet # dots:managed","timeout":30}]}]}}'

new=$(merge "$old" "$hook_on" "[\"$rule\"]")
check "the old hook is replaced, not added to" test "$(jq '.hooks.SessionStart | length' <<<"$new")" = 1
check "the new hook is orient's" test "$(jq -r '.hooks.SessionStart[0].hooks[0].command' <<<"$new")" = "/nix/store/x-orient/bin/orient --hook # dots:managed"
check "the permission rule is added" test "$(jq -c '.permissions.allow' <<<"$new")" = "[\"$rule\"]"
check "the author's settings are untouched" test "$(jq -c 'del(.hooks, .permissions.allow)' <<<"$new")" = "$(jq -c 'del(.hooks, .permissions.allow)' <<<"$old")"
check "running it again changes nothing" test "$(merge "$new" "$hook_on" "[\"$rule\"]")" = "$new"

# The author's own hooks and rules are kept, and the rule is not duplicated.
mine=$(jq -c '.hooks.PreToolUse = [{"matcher":"Bash","hooks":[{"type":"command","command":"echo hi"}]}] | .permissions.allow = ["Bash(git status)", "Bash(orient push-workbench)"] | .permissions.deny = ["Bash(rm -rf *)"]' <<<"$old")
out=$(merge "$mine" "$hook_on" "[\"$rule\"]")
check "another hook is kept" test "$(jq -c '.hooks.PreToolUse | length' <<<"$out")" = 1
check "other allow rules are kept, the rule once, others first" test "$(jq -c '.permissions.allow' <<<"$out")" = "[\"Bash(git status)\",\"$rule\"]"
check "deny rules are kept" test "$(jq -c '.permissions.deny' <<<"$out")" = '["Bash(rm -rf *)"]'

# Switched off: both go, the rest stays; and a file with no permissions block
# does not grow an empty one.
off=$(merge "$out" '{}' '[]')
check "off: the hook is gone" test "$(jq -c '.hooks | keys' <<<"$off")" = '["PreToolUse"]'
check "off: the rule is gone, the other kept" test "$(jq -c '.permissions.allow' <<<"$off")" = '["Bash(git status)"]'
bare=$(merge "$old" '{}' '[]')
check "off, nothing else allowed: no empty allow list is left" test "$(jq -c '.permissions' <<<"$bare")" = '{"defaultMode":"plan"}'
check "off: no hooks key is left empty" test "$(jq -c 'has("hooks")' <<<"$bare")" = false
none=$(merge '{"model":"sonnet"}' '{}' '[]')
check "off, no permissions block: none is created" test "$none" = "$(jq . <<<'{"model":"sonnet"}')"
fresh=$(merge '{"model":"sonnet"}' "$hook_on" "[\"$rule\"]")
check "on, no permissions block: one is created with the rule" test "$(jq -c '.permissions' <<<"$fresh")" = "{\"allow\":[\"$rule\"]}"

printf '\n%s failure(s)\n' "$fails"
exit $((fails > 0))
