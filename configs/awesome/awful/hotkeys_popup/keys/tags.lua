local hotkeys_popup = require("awful.hotkeys_popup.widget")

local tag_keys = {

  ["tag"] = { {
    modifiers = { "Mod4" },
    keys = {
      ["1..9"] = "view tag"
    }
  }, {
    modifiers = { "Mod4", "Control" },
    keys = {
      ["1..9"] = "toggle tag"
    }
  }, {
    modifiers = { "Mod4", "Shift" },
    keys = {
      ["1..9"] = "move focused client to tag"
    }
  }, {
    modifiers = { "Mod4", "Control", "Shift" },
    keys = {
      ["1..9"] = "toggle focused client on tag"
    }
  } }
}

hotkeys_popup.add_hotkeys(tag_keys)
