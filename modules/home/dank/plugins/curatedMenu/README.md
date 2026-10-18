# Curated menu

A keyboard menu of hand-picked commands, opened with **Mod+A**. It is a small local DMS plugin, so it uses DMS's theme
and needs nothing else running.

| Key | Does |
|---|---|
| `j` / `k` (or arrows, Tab / Shift+Tab) | move |
| Enter (or Right) | run the selected entry, or open its submenu |
| an entry's own key | run it (or open its submenu) at once |
| Esc / Backspace / Left | back one level; at the top, close |

## How it fits together

```
niri: Mod+A  ->  dms ipc call curatedMenu toggle            (modules/home/wm/niri/config.kdl)
                     |
DMS loads the plugin from ~/.config/DankMaterialShell/plugins/curatedMenu
                     |                                        (this folder, installed by curated-menu.nix)
CuratedMenu.qml reads its entries from plugin_settings.json (pluginData.entries)
                     ^
modules/home/dank/curated-menu.nix: option dank.curatedMenu.entries -> plugin settings
```

| File | What it is |
|---|---|
| `../../curated-menu.nix` | The entries (the option and its defaults), checks on them, and the helper scripts `dank-usb` and `dank-display-profiles` |
| `plugin.json` | Plugin manifest: a DMS *daemon* plugin, so it exists for the whole session and its IPC target is always there |
| `CuratedMenu.qml` | The IPC handler, the menu window, key handling, submenus |
| `../../../wm/niri/config.kdl` | The Mod+A bind |

Day to day you only edit `curated-menu.nix`. Touch the QML only to change how the menu looks or behaves.

## Adding an entry

Add an attribute set to the list in `curated-menu.nix`:

```nix
{
  key = "s";                 # one character, unique in its menu, not j or k
  label = "Screenshot";
  icon = "screenshot";       # a Material Symbols name: https://fonts.google.com/icons
  command = [dms "ipc" "call" "niri" "screenshot"];
}
```

`command` is an argv list, run directly with **no shell**. For pipes, `&&` or `$VARS`, wrap it:
`["sh" "-c" "grim - | wl-copy"]`. Prefer absolute paths (`"${pkgs.foo}/bin/foo"`, or the `dms` variable for DMS
itself): the command runs inside the DMS service, whose `PATH` is not your shell's.

Finding commands:
- Everything DMS can do over IPC: `dms ipc show` (targets and their functions), then try
  `dms ipc call <target> <function> [args]` in a terminal.
- DMS settings pages, for `settings openWith <tab>`: `dms ipc call settings tabs`. The "Display configuration" entry
  uses `display_config`.
- For a longer script, write it with `pkgs.writeShellScriptBin` in `curated-menu.nix`, as `dank-usb` is, and point
  `command` at it.

## Submenus

An entry has exactly **one** of `command`, `entries` or `generator`. The build fails with a message if that or the key
rules are broken.

### Static: `entries`

```nix
{
  key = "m";
  label = "Media";
  icon = "music_note";
  entries = [
    { key = "p"; label = "Play / pause"; icon = "play_pause"; command = [dms "ipc" "call" "mpris" "playPause"]; }
    { key = "n"; label = "Next";         icon = "skip_next";  command = [dms "ipc" "call" "mpris" "next"]; }
  ];
}
```

Keys only need to be unique within their own menu. In Nix, static submenus go one level deep; their entries need a
`command`.

### Generated: `generator`

For lists that change (devices, profiles, windows, ...), give an argv whose **stdout is a JSON array of entries**. It
runs every time the submenu opens:

```json
[
  { "key": "1", "label": "Desk (active)", "icon": "check_circle", "command": ["dank-display-profiles", "set", "Desk"] },
  { "label": "No key, reach me with j/k", "command": ["true"] }
]
```

- The fields are the same as in Nix. `key` may be left out (j/k + Enter still reach the entry). Use full paths in
  `command`.
- Entries may themselves have `entries` or `generator`, so generated menus can nest deeper than Nix-defined ones.
- If the generator prints nothing, prints something that isn't JSON, or prints an empty array, you get a toast saying
  so and stay where you were. Show something on the empty case yourself, as the display-profiles one does.
- Test a generator by running it in a terminal and piping it through `jq`.

**Worked example: Display profiles** (`p`). `dank-display-profiles menu` asks DMS for its profiles
(`dms ipc call outputs listProfiles`) and prints:
- with no profiles, a single entry that opens Display configuration, where profiles are created;
- otherwise, **Next profile** (`n`, cycles), **Automatic selection: on/off** (`a`, toggles; DMS refuses manual switches
  while it is on), then one entry per profile (`1`-`9`, the active one marked).

Choosing a profile runs `dank-display-profiles set NAME`, which reports DMS's answer as a toast. Use it as the template
for new generators: one script with a `menu` subcommand that prints the entries, and other subcommands as the actions.

## Per-host entries

The defaults are an ordinary definition, so another definition, for example in a host's home config in the hosts
repo, **adds** to them:

```nix
dank.curatedMenu.entries = lib.mkAfter [
  { key = "g"; label = "Game mode"; icon = "sports_esports"; command = [ ... ]; }
];
```

`lib.mkBefore` puts them first. `lib.mkForce [ ... ]` replaces the defaults entirely.

## Trying changes

1. Rebuild (`rebuild`). Entries and QML are both in the Nix store, so nothing changes before that.
2. The rebuild restarts DMS whenever a plugin or its settings changed (the bar blinks for a moment). This is needed:
   DMS reads `plugin_settings.json` only at startup, so `dms ipc call plugins reload curatedMenu` reloads the QML
   but keeps the old entries. If the menu still looks stale, `systemctl --user restart dms`.
   QML errors show up in `journalctl --user -u dms -f`.

Don't experiment by copying a plugin into `~/.config/DankMaterialShell/plugins` and enabling it from DMS. DMS rewrites
`plugin_settings.json` atomically, which replaces home-manager's symlink with a plain file and breaks the next
activation.

Testing QML before a rebuild (this is how the menu was developed): run a throwaway nested niri and a second,
isolated DMS inside it.

```sh
niri -c /tmp/t/niri.kdl &                    # a minimal config; the log names its socket (wayland-N)
WAYLAND_DISPLAY=wayland-N XDG_CONFIG_HOME=/tmp/t/config XDG_STATE_HOME=/tmp/t/state \
  XDG_CACHE_HOME=/tmp/t/cache DMS_SOCKET=/tmp/t/none \
  qs -p "$(dirname "$(readlink -f "$(which dms)")")/../share/quickshell/dms" &
```

Put the plugin folder and a hand-written `plugin_settings.json` in `/tmp/t/config/DankMaterialShell/`. Use harmless
test commands (`touch` a file). Pointing `DMS_SOCKET` at nothing keeps the test DMS away from your real one. Open the
menu with `qs ipc -i <instance> call curatedMenu open` (`qs list --all` names the instance on that display), and
reload after edits with `... call plugins reload curatedMenu`.

## Ideas not done

A radial layout; submenus for USB drives (one entry per drive) or windows; showing the entry's command in a tooltip.
