# dots options: home-manager

The `dots.*` options of `dots.homeModules.default`, the home-manager module set. The single-area modules (`homeModules.shell`, `vscode`, `nvim`, `flameshot`, `globalprotect`) declare a subset of them.

Generated from the modules' option declarations by `nix run .#update-options-reference`, and
kept in step by the `options-reference` check of `nix flake check`: to change anything here,
change the option's `description` (or its type, default or example) in the module named under
"Declared by". The NixOS side is in [options-nixos.md](options-nixos.md).

**Switches.** Every area has a `dots.<area>.enable`. "With the set" is what
`homeModules.default` itself leaves each one at, so an area is left out with
`dots.<area>.enable = false;` and no `mkForce`.

| Switch | With the set | What it adds |
| --- | --- | --- |
| [`dots.claude.enable`](#dotsclaudeenable) | on | Whether to enable Claude Code: its settings, hooks and the global instructions. |
| [`dots.dank.enable`](#dotsdankenable) | on | Whether to enable DankMaterialShell with its menus and settings handling. |
| [`dots.dictation.enable`](#dotsdictationenable) | off | Whether to enable offline voice dictation (voxtype with a Parakeet model). |
| [`dots.firefox.enable`](#dotsfirefoxenable) | on | Whether to enable Firefox policies and profiles. |
| [`dots.flameshot.enable`](#dotsflameshotenable) | off | Whether to enable Flameshot, the screenshot tool on Print (select, draw on it, pin it). |
| [`dots.git.enable`](#dotsgitenable) | on | Whether to enable the git configuration. |
| [`dots.globalprotect.enable`](#dotsglobalprotectenable) | off | Whether to enable the globalprotect command (GlobalProtect VPN through gpclient). |
| [`dots.latex.enable`](#dotslatexenable) | on | Whether to enable the LaTeX tools (tectonic and a small texlive). |
| [`dots.music.enable`](#dotsmusicenable) | on | Whether to enable music playback support (playerctl). |
| [`dots.navi.enable`](#dotsnavienable) | on | Whether to enable navi and its cheat sheets. |
| [`dots.niri.enable`](#dotsnirienable) | on | Whether to enable the niri window manager configuration. |
| [`dots.nixYourShell.enable`](#dotsnixyourshellenable) | on | Whether to enable nix-your-shell, which keeps zsh inside nix-shell and nix develop. |
| [`dots.nvim.enable`](#dotsnvimenable) | on | Whether to enable Neovim and its language setups. |
| [`dots.obsidian.enable`](#dotsobsidianenable) | on | Whether to enable Obsidian. |
| [`dots.opam.enable`](#dotsopamenable) | on | Whether to enable the opam global switch and the OCaml build tools. |
| [`dots.packages.enable`](#dotspackagesenable) | on | Whether to enable dots' general-purpose package list (the tools in home.packages below). |
| [`dots.repos.enable`](#dotsreposenable) | off | Whether to enable the repos CLI and, with DMS, the repositories bar menu. |
| [`dots.shell.enable`](#dotsshellenable) | on | Whether to enable the shell setup (zsh, kitty, tmux, starship, zoxide, direnv). |
| [`dots.stylix.enable`](#dotsstylixenable) | on | Whether to enable stylix theming (colours, fonts and the per-application targets). |
| [`dots.terminfo.enable`](#dotsterminfoenable) | on | Whether to enable kitty's terminfo entry in ~/.terminfo. |
| [`dots.vscode.enable`](#dotsvscodeenable) | on | Whether to enable VS Code with dots' settings, keybindings and profiles. |
| [`dots.wallpaper.enable`](#dotswallpaperenable) | on | Whether to enable the Bing wallpaper tools. |
| [`dots.zathura.enable`](#dotszathuraenable) | on | Whether to enable the zathura PDF reader. |

**Every option**, in alphabetical order:

## dots\.packages\.enable



Whether to enable dots’ general-purpose package list (the tools in home\.packages below)\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/default.nix)



## dots\.checkout

The absolute path of the mutable working copy of dots on this machine\. It must be a
real checkout of the repository, not a path in the Nix store\.



*Type:*
absolute path not in the Nix store



*Default:*

```nix
"${config.home.homeDirectory}/dots"
```



*Example:*

```nix
"/home/alice/src/dots"
```

*Declared by:*
 - [modules/home/checkout\.nix](https://github.com/thecathe/dots/blob/main/modules/home/checkout.nix)



## dots\.claude\.enable



Whether to enable Claude Code: its settings, hooks and the global instructions\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/claude/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/claude/default.nix)



## dots\.dank\.enable



Whether to enable DankMaterialShell with its menus and settings handling\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/dank/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/default.nix)



## dots\.dank\.curatedMenu\.entries



Entries of the curated menu (a DMS daemon plugin, opened with
` dms ipc call curatedMenu toggle `, bound to Mod+A in niri)\. Each entry
has exactly one of ` command `, ` entries ` (a static submenu) or
` generator ` (a submenu built when it opens)\. The defaults below are a
normal definition, not the option default, so any other definition
appends to them (` lib.mkAfter `/` lib.mkBefore ` to place it) and
` lib.mkForce ` replaces them\. See plugins/curatedMenu/README\.md\.



*Type:*
list of (submodule)

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.curatedMenu\.entries\.\*\.command



argv to run (no shell; wrap in ` sh -c ` if one is needed)\.



*Type:*
null or (list of string)



*Default:*

```nix
null
```

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.curatedMenu\.entries\.\*\.entries



Static submenu\.



*Type:*
list of (submodule)



*Default:*

```nix
[ ]
```

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.curatedMenu\.entries\.\*\.entries\.\*\.command



argv to run (no shell; wrap in ` sh -c ` if one is needed)\.



*Type:*
null or (list of string)



*Default:*

```nix
null
```

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.curatedMenu\.entries\.\*\.entries\.\*\.icon



Material Symbols icon name\.



*Type:*
string



*Default:*

```nix
"chevron_right"
```

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.curatedMenu\.entries\.\*\.entries\.\*\.key



Single character that picks this entry\. j and k are taken by navigation\.



*Type:*
string

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.curatedMenu\.entries\.\*\.entries\.\*\.label



Text shown for this entry in the menu\.



*Type:*
string

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.curatedMenu\.entries\.\*\.generator



argv run each time the submenu opens; it prints a JSON array of
entries ({key, label, icon, command}) on stdout\.



*Type:*
null or (list of string)



*Default:*

```nix
null
```

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.curatedMenu\.entries\.\*\.icon



Material Symbols icon name\.



*Type:*
string



*Default:*

```nix
"chevron_right"
```

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.curatedMenu\.entries\.\*\.key



Single character that picks this entry\. j and k are taken by navigation\.



*Type:*
string

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.curatedMenu\.entries\.\*\.label



Text shown for this entry in the menu\.



*Type:*
string

*Declared by:*
 - [modules/home/dank/curated-menu\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/curated-menu.nix)



## dots\.dank\.settingsOverlay



Host-specific values seeded into settings\.json on every activation\.
customThemeFile is always overwritten (a purely computed Nix store
path, nothing of the user’s to preserve)\. Everything else - showDock
(a dots\.dank\.settingsState key, declared by dock-toggle\.nix), every key
named in dots\.dank\.settingsOverlayKeys (whole values, e\.g\.
controlCenterWidgets), desktopWidgetInstances
position/displayPreferences data (keyed by widget id), and barConfigs
screenPreferences (keyed by bar id, e\.g\. \[{id: “default”,
screenPreferences: \[{name, model}]}, {id: “\<other bar id>”,
screenPreferences: \[…]}] - only the targeted-screens fragment, not a
full bar definition, since the rest of a bar’s config is genuinely
shared and tracked normally) - is seeded only where settings\.json
doesn’t already carry a real value (still at its canonical default,
or missing for that output), so a live DMS GUI change always wins
over this overlay\.
A key that none of those handle is a build error (see the assertions
below), rather than being silently ignored\.
activeDisplayProfile/desktopWidgetGridSettings used to be seeded here
too, but a DMS update moved them into session\.json, which is
gitignored/host-local and never reset by a checkout - so DMS’s own
normal use keeps them correct per host with no seeding needed; don’t
add them back here\.
The same update moved the desktop widget POSITIONS into session\.json,
and DMS reads them only from there; the positions seeded into
settings\.json are only for DMS’s migration of an old settings file\. So
the recorded positions also reach the session file, by the
dank-widget-positions command: a rebuild fills in the (widget, screen)
pairs the session has none for (which, since DMS stores a default the
first time it shows a widget on a screen, means a host that has not
shown it yet), and ` dank-widget-positions apply ` sets them all to the
record on request, restarting DMS around the write because DMS reads
the session only when it starts\. displayPreferences are still read from
settings\.json\.
None of this data is ever tracked by git in the first place - see
\.gitattributes and dankSettingsCleanFilter above, which strip it back
to canonical defaults on every git add/diff/status/commit\. This overlay
(applied by dankSettingsOverlayScript) exists purely to repopulate real
per-host values into the live file - both at rebuild time
(home\.activation\.dankMaterialShellSettingsOverlay) and reactively,
within moments of settings\.json’s content changing for any reason (the
dank-settings-repair systemd path unit), since a git checkout/pull can
reset it to canonical defaults at any time and there’s no way to stop
that at the git-filter level - see dankSettingsOverlayScript’s comment
above for why\. Keeps per-host facts from leaking into the shared file
the same way the hosts repo’s nixos/modules/home/monitor\.nix does for niri’s own
output config\. See \<host>/modules/home/dank-monitor\.json in the hosts repo\.



*Type:*
attribute set of anything



*Default:*

```nix
{ }
```

*Declared by:*
 - [modules/home/dank/dms\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/dms.nix)



## dots\.dank\.settingsOverlayKeys



Top-level settings\.json keys whose whole value belongs to the host, not
to the shared file\. Adding a key here is all it takes to make it
host-specific: the clean filter deletes it on the way into git (so the
shared file never carries it), and the overlay seeds the host’s value
from dots\.dank\.settingsOverlay\.\<key> when the live file has none\. Absent is
the canonical default because DMS omits a key from the file while it is
at its own default\. Like everything in the overlay, a live DMS GUI change
wins: the key stays as DMS wrote it until the host’s own copy in
dots\.dank\.settingsOverlay is updated by hand\. (So resetting the key to DMS’s
default in the GUI removes it, and the host’s value comes back\.)

Only for keys that are replaced as a whole\. Keys merged per entry
(desktopWidgetInstances, barConfigs) and state keys (dots\.dank\.settingsState)
have their own handling\. A definition here is a normal one, so a host
appends with a plain assignment; dms\.nix sets the base list\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "controlCenterWidgets"
]
```

*Declared by:*
 - [modules/home/dank/dms\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/dms.nix)



## dots\.dank\.settingsState



settings\.json keys that are state rather than config, each with the
canonical default it is reset to on the way into git (see
dankSettingsCleanFilter) and that a host’s real value is seeded over
when the live file is still at it (see dankSettingsOverlayScript)\. A
fact about DMS’s own schema, not a per-host fact: declared by the module
that owns the key (dock-toggle\.nix declares showDock), where the host’s
value, if any, then goes in dots\.dank\.settingsOverlay\.



*Type:*
attribute set of anything



*Default:*

```nix
{ }
```



*Example:*

```nix
{
  showDock = true;
}
```

*Declared by:*
 - [modules/home/dank/dms\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dank/dms.nix)



## dots\.devlog\.claudeHook



Add ` orient --hook ` (a pull-only ` dlsync ` and the start-of-session
preamble) to Claude Code’s SessionStart hooks (on startup and resume),
and allow the one command ` orient push-workbench ` without a prompt\. Both
are merged into the mutable ` ~/.claude/settings.json ` on every
activation\. Has no effect while ` dir ` is null\.



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [modules/home/devlog/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/devlog/default.nix)



## dots\.devlog\.dir



This host’s clone of the shared devlog repo\. Setting it installs ` dlsync `,
which fetches origin and fast-forwards or merges ` main ` into the clone
(` dlsync --push ` then publishes it), failing loudly with the clone left
as it was whenever it cannot; and ` orient `, which runs ` dlsync `, reads
` registry.toml ` in the clone and tells a session about its repository\.
Null disables the feature\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"/home/me/Documents/git/me/devlog"
```

*Declared by:*
 - [modules/home/devlog/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/devlog/default.nix)



## dots\.dictation\.enable



Whether to enable offline voice dictation (voxtype with a Parakeet model)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/dictation/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dictation/default.nix)



## dots\.dictation\.package



The voxtype package\. It has to be built with ONNX support, or the
Parakeet engine is missing\.



*Type:*
package



*Default:*

```nix
pkgs.voxtype.override { onnxSupport = true; }, plus oniguruma and sqlite
```

*Declared by:*
 - [modules/home/dictation/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dictation/default.nix)



## dots\.dictation\.bind



The niri key that starts and stops dictation\. Takes effect on hosts that
use dots’ niri module\.



*Type:*
string



*Default:*

```nix
"Mod+D"
```



*Example:*

```nix
"Mod+Alt+D"
```

*Declared by:*
 - [modules/home/dictation/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dictation/default.nix)



## dots\.dictation\.keyboardLayout



The XKB layout of the keyboard, which dotool needs in order to press the
right keys for each character\. It has to match the layout niri uses (the
` xkb { layout } ` setting in niri’s config\.kdl, “gb” there): dotool does
not follow a layout change made while it runs\.



*Type:*
string



*Default:*

```nix
"gb"
```



*Example:*

```nix
"us"
```

*Declared by:*
 - [modules/home/dictation/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dictation/default.nix)



## dots\.dictation\.model



Which Parakeet model directory to use (see models\.nix): ` v2-int8 ` is the
8-bit quantised model, ` v2 ` the full-precision one\. On the CPU they are as
fast and gave the same text, but ` v2 ` needs over twice the memory\.



*Type:*
one of “override”, “overrideDerivation”, “v2”, “v2-int8”



*Default:*

```nix
"v2-int8"
```

*Declared by:*
 - [modules/home/dictation/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dictation/default.nix)



## dots\.dictation\.settings



voxtype’s config\.toml, as an attribute set\. Only what differs from
voxtype’s own defaults needs to be here; the defaults set by this module
can be replaced with a plain assignment\.



*Type:*
TOML value



*Default:*

```nix
{ }
```



*Example:*

```nix
{
  text = {
    spoken_punctuation = true;
  };
}
```

*Declared by:*
 - [modules/home/dictation/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/dictation/default.nix)



## dots\.firefox\.enable



Whether to enable Firefox policies and profiles\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/firefox/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/firefox/default.nix)



## dots\.firefox\.profile



The main Firefox profile’s name, which is also its directory: changing it
on a machine that already has a profile starts a new, empty one\.



*Type:*
string



*Default:*

```nix
config.home.username
```

*Declared by:*
 - [modules/home/firefox/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/firefox/default.nix)



## dots\.flameshot\.enable



Whether to enable Flameshot, the screenshot tool on Print (select, draw on it, pin it)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/flameshot/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/flameshot/default.nix)



## dots\.flameshot\.package



The flameshot package to use\.



*Type:*
package



*Default:*

```nix
pkgs.flameshot
```

*Declared by:*
 - [modules/home/flameshot/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/flameshot/default.nix)



## dots\.flameshot\.bind



The niri key that opens Flameshot’s selection overlay\. Takes effect on
hosts that use dots’ niri module\. If it is a key config\.kdl already
binds, this one wins\.



*Type:*
string



*Default:*

```nix
"Print"
```



*Example:*

```nix
"Mod+Shift+S"
```

*Declared by:*
 - [modules/home/flameshot/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/flameshot/default.nix)



## dots\.flameshot\.niriBind



The niri key that keeps niri’s own region screenshot (` screenshot `)
reachable once ` bind ` has taken Print: a selector that needs nothing
running, for when Flameshot’s daemon is down\. ` null ` leaves it unbound\.



*Type:*
null or string



*Default:*

```nix
"Shift+Print"
```



*Example:*

```nix
null
```

*Declared by:*
 - [modules/home/flameshot/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/flameshot/default.nix)



## dots\.flameshot\.portalPngLevel



PNG compression level (0 to 9) of the screenshot the wlr portal takes, when
` wlrScreenshotPortal ` is on\. The default grim level is 6 and takes about
540 ms for the two outputs of ` nixos `; 0 stores the pixels uncompressed (about
100 ms, a 23 MB temporary file that Flameshot deletes once it has loaded it)\.
The picture is the same at every level\.



*Type:*
integer between 0 and 9 (both inclusive)



*Default:*

```nix
0
```

*Declared by:*
 - [modules/home/flameshot/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/flameshot/default.nix)



## dots\.flameshot\.screenOrder



The outputs in the order Flameshot (Qt) numbers them, which follows the
order the compositor announces them, not their position\. With this set,
Print opens the overlay straight on the output the pointer is on instead
of asking which one: the wrapper takes the focused output’s name from
niri and passes its place in this list to ` flameshot screen --edit -n `\.
List every output the host can have: only the ones switched on at the
time count, so with the Dell off the AOC is number 0, not 1\. An output
that is on but not in the list gets the plain ` flameshot gui ` (with its
question, unless it is the only screen)\. To find the order on a host, run
` flameshot screen -n 0 -p /tmp/f ` and then ` -n 1 `, and compare the images’
sizes with ` niri msg outputs `\. If the wrong output shows up later, the
order changed (a monitor was unplugged and replugged, for instance) and
this list is what to fix\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "HDMI-A-1"
  "DP-1"
]
```

*Declared by:*
 - [modules/home/flameshot/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/flameshot/default.nix)



## dots\.flameshot\.settings



Flameshot’s ` flameshot.ini `, as an attribute set of sections\. Only what
differs from Flameshot’s own defaults needs to be here (the defaults set
by this module can be replaced with a plain assignment)\. The keys are
listed in Flameshot’s ` flameshot.example.ini `\.



*Type:*
attribute set of section of an INI file (attrs of INI atom (null, bool, int, float or string))



*Default:*

```nix
{ }
```



*Example:*

```nix
{
  General = {
    showHelp = false;
  };
}
```

*Declared by:*
 - [modules/home/flameshot/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/flameshot/default.nix)



## dots\.flameshot\.wlrScreenshotPortal



Serve the XDG Screenshot portal from xdg-desktop-portal-wlr (which runs
` grim `) instead of from niri\. Needed on a host with more than one output:
niri 26\.04’s own handler refuses to capture then, and Flameshot has no
other way to capture on Wayland (see the top of this file)\. Adds the
portal to home-manager’s portal set, starts it as a user service, and
writes the user-level ` niri-portals.conf ` with Screenshot pointed at it\.
That file replaces the system one rather than merging with it, so it
repeats the rest of niri’s list (gnome and gtk, with Access, FileChooser,
Notification and Secret as they are on ` nixos `); a host that sets the
same file itself (the work laptop’s ` xdg.configFile `) must not turn this on\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [modules/home/flameshot/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/flameshot/default.nix)



## dots\.git\.enable



Whether to enable the git configuration\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/git/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/git/default.nix)



## dots\.globalprotect\.enable



Whether to enable the globalprotect command (GlobalProtect VPN through gpclient)\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/globalprotect/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/globalprotect/default.nix)



## dots\.globalprotect\.package



The gpclient package to use\.



*Type:*
package



*Default:*

```nix
pkgs.gpclient
```

*Declared by:*
 - [modules/home/globalprotect/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/globalprotect/default.nix)



## dots\.globalprotect\.authPackage



The gpauth package to use\.



*Type:*
package



*Default:*

```nix
pkgs.gpauth
```

*Declared by:*
 - [modules/home/globalprotect/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/globalprotect/default.nix)



## dots\.globalprotect\.browser



The browser gpauth opens for the login: ` auto ` (Chrome, then Firefox,
then the system default), ` default ` (the system default) or a browser
name\.



*Type:*
string



*Default:*

```nix
"auto"
```



*Example:*

```nix
"firefox"
```

*Declared by:*
 - [modules/home/globalprotect/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/globalprotect/default.nix)



## dots\.globalprotect\.connectArgs



Extra arguments for ` gpclient connect `, e\.g\. a fixed gateway (otherwise
gpclient asks) or ` --hip ` for portals that require a host-integrity report\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "--gateway"
  "gateway.example.com"
]
```

*Declared by:*
 - [modules/home/globalprotect/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/globalprotect/default.nix)



## dots\.globalprotect\.portal



The GlobalProtect portal to connect to (host name only)\. Required when
enabled: it names an organisation, so dots does not default it\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"vpn.example.com"
```

*Declared by:*
 - [modules/home/globalprotect/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/globalprotect/default.nix)



## dots\.latex\.enable



Whether to enable the LaTeX tools (tectonic and a small texlive)\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/latex\.nix](https://github.com/thecathe/dots/blob/main/modules/home/latex.nix)



## dots\.music\.enable



Whether to enable music playback support (playerctl)\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/music/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/music/default.nix)



## dots\.navi\.enable



Whether to enable navi and its cheat sheets\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/navi/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/navi/default.nix)



## dots\.niri\.enable



Whether to enable the niri window manager configuration\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/wm/niri/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/wm/niri/default.nix)



## dots\.nixYourShell\.enable



Whether to enable nix-your-shell, which keeps zsh inside nix-shell and nix develop\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/nix-your-shell\.nix](https://github.com/thecathe/dots/blob/main/modules/home/nix-your-shell.nix)



## dots\.nixd\.flake



Path of the flake that defines the hosts\. Use the real path, not a
symlink: builtins\.getFlake rejects symlinks\. Its nixosConfigurations /
homeConfigurations supply the options nixd completes, and its ` nixpkgs `
input supplies nixpkgs\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"/home/me/hosts"
```

*Declared by:*
 - [modules/home/nixd\.nix](https://github.com/thecathe/dots/blob/main/modules/home/nixd.nix)



## dots\.nixd\.homeConfiguration



Name of the homeConfiguration whose options nixd completes\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"me@host"
```

*Declared by:*
 - [modules/home/nixd\.nix](https://github.com/thecathe/dots/blob/main/modules/home/nixd.nix)



## dots\.nixd\.nixosHost



Name of the nixosConfiguration whose options nixd completes\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"nixos"
```

*Declared by:*
 - [modules/home/nixd\.nix](https://github.com/thecathe/dots/blob/main/modules/home/nixd.nix)



## dots\.nvim\.enable



Whether to enable Neovim and its language setups\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/nvim/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/nvim/default.nix)



## dots\.obsidian\.enable



Whether to enable Obsidian\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/obsidian/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/obsidian/default.nix)



## dots\.opam\.enable



Whether to enable the opam global switch and the OCaml build tools\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/opam/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/opam/default.nix)



## dots\.repos\.enable



Whether to enable the repos CLI and, with DMS, the repositories bar menu\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/repos/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/repos/default.nix)



## dots\.repos\.package



The ` repos ` CLI; the DMS menu runs this one\.



*Type:*
package



*Default:*
the ` repos ` CLI built from the options above

*Declared by:*
 - [modules/home/repos/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/repos/default.nix)



## dots\.repos\.exclude



Repositories (` <owner>/<name> `) to leave out, e\.g\. a huge checkout that is slow to status\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "facebook/infer"
]
```

*Declared by:*
 - [modules/home/repos/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/repos/default.nix)



## dots\.repos\.hoverDelayMs



How long, in milliseconds, the pointer must rest on the bar pill before
it grows to the overview of counts (and checks the repositories again if
the last check is old)\. A pointer sweeping past does nothing; ` 0 ` shows
the overview at once\. Read by the DMS menu only\.



*Type:*
integer between 0 and 10000 (both inclusive)



*Default:*

```nix
250
```



*Example:*

```nix
600
```

*Declared by:*
 - [modules/home/repos/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/repos/default.nix)



## dots\.repos\.integrationBranch



The branch finished work is merged into, per repository (` <owner>/<name> `),
for repositories where it is not ` main ` (or ` master `)\. Branches are
reported as merged or not against it\.



*Type:*
attribute set of string



*Default:*

```nix
{ }
```



*Example:*

```nix
{
  "thecathe/ocaml-forester" = "redirect-meta";
}
```

*Declared by:*
 - [modules/home/repos/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/repos/default.nix)



## dots\.repos\.owners



Only list the repositories of these owners (the directory under ` root `)\.
Empty, the default, lists every owner\. This is what the menu, the
` repos ` table and a bare ` repos fetch ` cover; ` exclude ` still removes
single repositories from what is left\. A repository named to ` repos `
explicitly (` repos path owner/name `) is found whatever this says\.



*Type:*
list of string matching the pattern \[^/]+



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  "thecathe"
]
```

*Declared by:*
 - [modules/home/repos/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/repos/default.nix)



## dots\.repos\.root



The directory holding the repositories, laid out as ` <root>/<owner>/<name> `\.



*Type:*
string



*Default:*

```nix
"${config.home.homeDirectory}/Documents/git"
```

*Declared by:*
 - [modules/home/repos/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/repos/default.nix)



## dots\.services



Services switched on and off by hand\. See the comment at the top of modules/shared/services\.nix\.



*Type:*
attribute set of (submodule)



*Default:*

```nix
{ }
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.actions



Extra actions for the services menu\. A service with any gets a “…”
button on its row that lists them; one without has no button\. Only the
menu uses them: they do not appear in the CLI\.



*Type:*
list of (submodule)



*Default:*

```nix
[ ]
```



*Example:*

```nix
[
  {
    argv = [
      "tmux"
      "attach"
    ];
    icon = "terminal";
    label = "Attach to console";
    terminal = true;
  }
]
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.actions\.\*\.argv



The command (argv) the action runs\.



*Type:*
list of string



*Default:*

```nix
[ ]
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.actions\.\*\.icon



A Material Symbols icon name for the action\.



*Type:*
string



*Default:*

```nix
"chevron_right"
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.actions\.\*\.label



The name the menu shows for the action\.



*Type:*
string

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.actions\.\*\.requiresUp



List the action only while the service is up: for commands that talk
to the running service and would just fail while it is down\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.actions\.\*\.terminal



Run the command in a terminal window (kitty) rather than in the
background: for commands that are interactive or stay up, e\.g\.
attaching to a tmux session\. The window closes when the command
ends, and waits for Enter if it failed so the error can be read\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.command



If set, installs a ` <command> up|down|status ` CLI\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"immich"
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.detail



A command (argv) that prints one short word about what an up service
is doing right now (e\.g\. “recording”), or nothing\. The menu shows the
word in the error colour in place of “up”\. It runs after ` status `
succeeds, each time the menu opens, so keep it cheap\. Only the menu
uses it\.



*Type:*
null or (list of string)



*Default:*

```nix
null
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.down



The command (argv) that takes the service down\.



*Type:*
list of string



*Default:*

```nix
[ ]
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.fallback



A program the CLI hands any other arguments to, for a command whose name a real program already uses\.



*Type:*
null or string



*Default:*

```nix
null
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.icon



A Material Symbols icon name for the services menu\.



*Type:*
string



*Default:*

```nix
"settings"
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.label



The name the services menu shows\.



*Type:*
string



*Default:*

```nix
"‹name›"
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.status



The command (argv) that exits 0 while the service is up\. It runs each time the services menu opens, so keep it cheap\.



*Type:*
list of string



*Default:*

```nix
[ ]
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.unit



A systemd unit (with its suffix) that is the service\. up, down and
status then default to starting, stopping and checking it, and on
NixOS the dots user may start and stop it without a password\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"immich.target"
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.up



The command (argv) that brings the service up\.



*Type:*
list of string



*Default:*

```nix
[ ]
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.services\.\<name>\.userUnit



Whether unit is a user unit (systemctl --user) rather than a system one\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [modules/shared/services\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/services.nix)



## dots\.shell\.enable



Whether to enable the shell setup (zsh, kitty, tmux, starship, zoxide, direnv)\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/shell/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/shell/default.nix)



## dots\.stylix\.enable



Whether to enable stylix theming (colours, fonts and the per-application targets)\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/stylix/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/stylix/default.nix)



## dots\.terminfo\.enable



Whether to enable kitty’s terminfo entry in ~/\.terminfo\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/terminfo\.nix](https://github.com/thecathe/dots/blob/main/modules/home/terminfo.nix)



## dots\.user\.git\.email



The email git records on commits\. Unset leaves git’s user\.email alone\.



*Type:*
null or string



*Default:*

```nix
null
```

*Declared by:*
 - [modules/shared/identity\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/identity.nix)



## dots\.user\.git\.name



The name git records on commits\. Unset leaves git’s user\.name alone\.



*Type:*
null or string



*Default:*

```nix
null
```

*Declared by:*
 - [modules/shared/identity\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/identity.nix)



## dots\.user\.name



The dots user’s login name\.



*Type:*
string

*Declared by:*
 - [modules/shared/identity\.nix](https://github.com/thecathe/dots/blob/main/modules/shared/identity.nix)



## dots\.vscode\.enable



Whether to enable VS Code with dots’ settings, keybindings and profiles\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/vscode/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/vscode/default.nix)



## dots\.vscode\.profileUiState\.enable



Create globalStorage for declared profiles and seed their UI layout from the default profile\.



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [modules/home/vscode/profile-ui-state\.nix](https://github.com/thecathe/dots/blob/main/modules/home/vscode/profile-ui-state.nix)



## dots\.vscode\.profileUiState\.filesContainer



ID of the (generated) view container that holds the file tree in the
default profile\. If set, and the default profile’s saved layout
contains it, Open Editors, Outline and Timeline are moved into it
(they can end up stranded in the never-shown Remote Explorer
container)\. Container IDs are per-install; leave null to skip\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"workbench.views.service.sidebar.4337fe0b-3e0d-40ce-9701-c62f345cfd7a"
```

*Declared by:*
 - [modules/home/vscode/profile-ui-state\.nix](https://github.com/thecathe/dots/blob/main/modules/home/vscode/profile-ui-state.nix)



## dots\.vscode\.profileUiState\.seed



Run the activation step that seeds profile UI layout from the default profile\. Disable to only create the globalStorage dirs\.



*Type:*
boolean



*Default:*

```nix
true
```

*Declared by:*
 - [modules/home/vscode/profile-ui-state\.nix](https://github.com/thecathe/dots/blob/main/modules/home/vscode/profile-ui-state.nix)



## dots\.vscode\.profiles



The profiles to build besides ` default `, which is always built\. Names are those in groups\.nix\.



*Type:*
list of (one of “cloakaml”, “erlang”, “forester”, “go”, “haskell”, “indimo”, “java”, “latex”, “mebi”, “ocaml”, “python”, “rocq”, “webserver”)



*Default:*
every profile in ` groups.nix `



*Example:*

```nix
[
  "python"
  "rocq"
]
```

*Declared by:*
 - [modules/home/vscode/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/vscode/default.nix)



## dots\.vscode\.remoteSsh



Whether to add Remote-SSH (Microsoft’s proprietary extension, with Remote
Explorer and Remote-SSH Edit) to every profile, and have it install Claude Code
on each host a remote window connects to\. A remote window resolves its
connection with the extensions of the profile it opens in, so a workspace pinned
to any profile needs it, not only the profiles whose group already lists the
` ssh ` feature\. Off by default: it is unfree and most setups never connect out\.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [modules/home/vscode/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/vscode/default.nix)



## dots\.vscode\.workspaces\.dir



Directory of \*\.code-workspace files plus a manifest\.json (profiles, repos,
untracked)\. Folder paths inside the workspace files are relative to this
directory, which must therefore be a real directory and not reached through
a symlink: VSCode resolves those paths against the path a file was opened by,
and its file dialog returns the real path, so through a symlink the same file
points at two different places\. ` code-workspace --check ` verifies this\.
Null disables the feature\.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"/home/me/workspaces/vscode"
```

*Declared by:*
 - [modules/home/vscode/workspaces\.nix](https://github.com/thecathe/dots/blob/main/modules/home/vscode/workspaces.nix)



## dots\.wallpaper\.enable



Whether to enable the Bing wallpaper tools\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/wallpaper/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/wallpaper/default.nix)



## dots\.zathura\.enable



Whether to enable the zathura PDF reader\.



*Type:*
boolean



*Default:*

```nix
true
```



*Example:*

```nix
true
```

*Declared by:*
 - [modules/home/zathura/default\.nix](https://github.com/thecathe/dots/blob/main/modules/home/zathura/default.nix)


