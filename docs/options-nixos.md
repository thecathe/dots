# dots options: NixOS

The `dots.*` options of `dots.nixosModules.default`, the NixOS module set.

Generated from the modules' option declarations by `nix run .#update-options-reference`, and
kept in step by the `options-reference` check of `nix flake check`: to change anything here,
change the option's `description` (or its type, default or example) in the module named under
"Declared by". The home-manager side is in [options-home.md](options-home.md).

**Switches.** Every area has a `dots.<area>.enable`. "With the set" is what
`nixosModules.default` itself leaves each one at, so an area is left out with
`dots.<area>.enable = false;` and no `mkForce`.

| Switch | With the set | What it adds |
| --- | --- | --- |
| [`dots.claude.enable`](#dotsclaudeenable) | off | Whether to enable Claude Code and its usage monitor, for every user. |
| [`dots.direnv.enable`](#dotsdirenvenable) | on | Whether to enable direnv with nix-direnv. |
| [`dots.docker.enable`](#dotsdockerenable) | off | Whether to enable Docker. |
| [`dots.firefox.enable`](#dotsfirefoxenable) | on | Whether to enable Firefox with dots' policies. |
| [`dots.fonts.enable`](#dotsfontsenable) | on | Whether to enable dots' font packages. |
| [`dots.git.enable`](#dotsgitenable) | on | Whether to enable git with LFS and dots' defaults. |
| [`dots.gpuScreenRecorder.enable`](#dotsgpuscreenrecorderenable) | off | Whether to enable GPU Screen Recorder, a ShadowPlay-style recorder with an instant-replay buffer and an overlay UI, which the niri module binds to Mod+Alt+Z (and Mod+Alt+F6..F12, see modules/home/wm/niri/gsr-binds.kdl). |
| [`dots.immich.enable`](#dotsimmichenable) | off | Whether to enable Immich, self-hosted photo and video management. |
| [`dots.media.enable`](#dotsmediaenable) | off | Whether to enable the music player and the thumbnail generators. |
| [`dots.nautilus.enable`](#dotsnautilusenable) | on | Whether to enable the Nautilus file manager and gvfs. |
| [`dots.niri.enable`](#dotsnirienable) | on | Whether to enable the niri compositor (the system side). |
| [`dots.nixLd.enable`](#dotsnixldenable) | on | Whether to enable nix-ld, so prebuilt Linux binaries run unmodified. |
| [`dots.samba.enable`](#dotssambaenable) | off | Whether to enable Samba file sharing, advertised on the local network (wsdd, avahi). |
| [`dots.stylix.enable`](#dotsstylixenable) | on | Whether to enable stylix theming (the system side). |
| [`dots.tailscale.enable`](#dotstailscaleenable) | off | Whether to enable Tailscale, with the per-user tools. |
| [`dots.terminfo.enable`](#dotsterminfoenable) | on | Whether to enable kitty's terminfo for every user, root included. |
| [`dots.torrent.enable`](#dotstorrentenable) | off | Whether to enable qBittorrent and Tor Browser. |
| [`dots.vscode.enable`](#dotsvscodeenable) | on | Whether to enable stock VS Code, system-wide. |
| [`dots.waydroid.enable`](#dotswaydroidenable) | off | Whether to enable Waydroid, Android in a container (started by hand). |
| [`dots.zsh.enable`](#dotszshenable) | on | Whether to enable zsh as the system shell, with dots' defaults. |

**Every option**, in alphabetical order:

## dots\.claude\.enable

Whether to enable Claude Code and its usage monitor, for every user\.



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
 - [modules/nixos/claude\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/claude.nix)



## dots\.direnv\.enable



Whether to enable direnv with nix-direnv\.



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
 - [modules/nixos/direnv\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/direnv.nix)



## dots\.docker\.enable



Whether to enable Docker\. Membership of the docker group is root-equivalent: anyone in it
can start a privileged container\.



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
 - [modules/nixos/docker\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/docker.nix)



## dots\.firefox\.enable



Whether to enable Firefox with dots’ policies\.



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
 - [modules/nixos/firefox\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/firefox.nix)



## dots\.fonts\.enable



Whether to enable dots’ font packages\.



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
 - [modules/nixos/fonts\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/fonts.nix)



## dots\.git\.enable



Whether to enable git with LFS and dots’ defaults\.



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
 - [modules/nixos/git\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/git.nix)



## dots\.gpuScreenRecorder\.enable



Whether to enable GPU Screen Recorder, a ShadowPlay-style recorder with an instant-replay
buffer and an overlay UI, which the niri module binds to Mod+Alt+Z (and
Mod+Alt+F6…F12, see modules/home/wm/niri/gsr-binds\.kdl)\. Installs two setcap
wrappers: gsr-kms-server (cap_sys_admin, for promptless capture) and
gsr-global-hotkeys (cap_setuid, which only the recorder’s own hotkeys use)\.



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
 - [modules/nixos/gpu-screen-recorder\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/gpu-screen-recorder.nix)



## dots\.gpuScreenRecorder\.settings



Settings of the UI (keys of ~/\.config/gpu-screen-recorder/config_ui, as
that file spells them) to set to these values each time the service
starts\. Everything else stays whatever the UI saved\. See pinScript in
modules/nixos/gpu-screen-recorder\.nix for the limits: nothing is set
before the UI has written the file once, and a key that repeats (audio
tracks) cannot be set\.



*Type:*
attribute set of string



*Default:*

```nix
{ }
```



*Example:*

```nix
{
  "record.save_directory" = "/mnt/data/Videos";
}
```

*Declared by:*
 - [modules/nixos/gpu-screen-recorder\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/gpu-screen-recorder.nix)



## dots\.immich\.enable



Whether to enable Immich, self-hosted photo and video management\.



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
 - [modules/nixos/media/immich/default\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/media/immich/default.nix)



## dots\.immich\.mediaLocation



Where Immich keeps the photos and videos it manages\.



*Type:*
string



*Default:*

```nix
"/var/lib/immich"
```



*Example:*

```nix
"/mnt/data/Multimedia/immich"
```

*Declared by:*
 - [modules/nixos/media/immich/default\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/media/immich/default.nix)



## dots\.media\.enable



Whether to enable the music player and the thumbnail generators\.



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
 - [modules/nixos/media/default\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/media/default.nix)



## dots\.nautilus\.enable



Whether to enable the Nautilus file manager and gvfs\.



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
 - [modules/nixos/nautilus\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/nautilus.nix)



## dots\.niri\.enable



Whether to enable the niri compositor (the system side)\.



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
 - [modules/nixos/niri\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/niri.nix)



## dots\.nixLd\.enable



Whether to enable nix-ld, so prebuilt Linux binaries run unmodified\.



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
 - [modules/nixos/nix-ld\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/nix-ld.nix)



## dots\.samba\.enable



Whether to enable Samba file sharing, advertised on the local network (wsdd, avahi)\.



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
 - [modules/nixos/network-sharing\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/network-sharing.nix)



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



## dots\.stylix\.enable



Whether to enable stylix theming (the system side)\.



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
 - [modules/nixos/stylix\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/stylix.nix)



## dots\.tailscale\.enable



Whether to enable Tailscale, with the per-user tools\.



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
 - [modules/nixos/tailscale\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/tailscale.nix)



## dots\.terminfo\.enable



Whether to enable kitty’s terminfo for every user, root included\.



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
 - [modules/nixos/terminfo\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/terminfo.nix)



## dots\.torrent\.enable



Whether to enable qBittorrent and Tor Browser\.



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
 - [modules/nixos/torrent/default\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/torrent/default.nix)



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



Whether to enable stock VS Code, system-wide\.



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
 - [modules/nixos/vscode\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/vscode.nix)



## dots\.waydroid\.enable



Whether to enable Waydroid, Android in a container (started by hand)\.



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
 - [modules/nixos/waydroid/default\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/waydroid/default.nix)



## dots\.zsh\.enable



Whether to enable zsh as the system shell, with dots’ defaults\.



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
 - [modules/nixos/zsh\.nix](https://github.com/thecathe/dots/blob/main/modules/nixos/zsh.nix)


