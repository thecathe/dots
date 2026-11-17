# Make the parts of a Claude Code settings file that dots manages equal what
# dots wants, leaving everything else alone.
#
# Hooks: $managed is event name -> list of hook groups. A hook group is dots'
# own if one of its commands carries the `# dots:managed` marker, so removing a
# hook from the Nix side removes it from the file too.
#
# Permissions: $allow is the allow rules dots wants present, $allowKnown every
# rule dots has ever managed. A permission string has nowhere to carry a marker,
# so the known list is the marker: those rules are taken out and the wanted ones
# put back. A rule dots stops managing must stay in $allowKnown, or it would
# never be removed again.
def isManaged: any(.hooks[]?; (.command // "") | contains("# dots:managed"));

((.hooks // {}) | map_values(map(select(isManaged | not))) | with_entries(select(.value | length > 0))) as $others
| .hooks = (reduce ($managed | keys[]) as $event ($others; .[$event] = ((.[$event] // []) + $managed[$event])))
| if (.hooks | length) == 0 then del(.hooks) else . end
| ((.permissions.allow // []) | map(select(. as $rule | $allowKnown | index($rule) | not)) + $allow) as $rules
| if ($rules | length) > 0 then .permissions.allow = $rules
  elif (.permissions | type) == "object" then del(.permissions.allow)
  else . end
