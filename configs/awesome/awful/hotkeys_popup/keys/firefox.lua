local hotkeys_popup = require("awful.hotkeys_popup.widget")

for group_name, group_data in pairs({
  ["Firefox: tabs"] = { rule_any = { class = { "firefox" } } }
}) do
  hotkeys_popup.add_group_rules(group_name, group_data)
end

local firefox_keys = {

  ["Firefox: tabs"] = { {
    modifiers = { "Mod1" },
    keys = {
      ["1..9"] = "go to tab"
    }
  }, {
    modifiers = { "Ctrl" },
    keys = {
      t = "new tab",
      w = 'close tab',
      ['Tab'] = "next tab"
    }
  }, {
    modifiers = { "Ctrl", "Shift" },
    keys = {
      ['Tab'] = "previous tab"
    }
  } }
}

hotkeys_popup.add_hotkeys(firefox_keys)
