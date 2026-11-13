# Make the hooks in a Claude Code settings file that dots manages equal $managed
# (event name -> list of hook groups), leaving every other hook alone. A hook
# group is dots' own if one of its commands carries the `# dots:managed` marker,
# so removing a hook from the Nix side removes it from the file too.
def isManaged: any(.hooks[]?; (.command // "") | contains("# dots:managed"));

((.hooks // {}) | map_values(map(select(isManaged | not))) | with_entries(select(.value | length > 0))) as $others
| .hooks = (reduce ($managed | keys[]) as $event ($others; .[$event] = ((.[$event] // []) + $managed[$event])))
| if (.hooks | length) == 0 then del(.hooks) else . end
