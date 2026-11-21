# dots

## todo

- fix gnome wayland issues, e.g., steamlink fullscreen not capturing
- unpack templates into dots shells and templates that reuse them. allows for more modular project setups e.g., in the case a project uses multiple languages

### nvim

- update nvim to use nvf or nixvim
  - lazynvim with nix stuff? what are the benefits, cos it feels like it may just be compounding the issue of having lots of lua stuff inside of a nix.
- how to do vscode equivalent of `ctrl+shift+up/down` to columnwise select with cursor
- how to configure certain sessions (like vscode workspaces) to show certain hidden directories/files?
- markdown auto bullet-points
- picker files to only show project files rather than all. (e.,g \fr shows ALL recent files, which isn't that useful)
  - picker popup to filter out pdfs? only show them in explorer?
- auto-close empty buffer with any other buffers open
- still issue with closing buffer with explorer open making everything difficult.
  - similar (ish) issue with `snacks.terminal` popping in and out of insert mode.
- \gx not working in certain cases (e.g., on actual pdf md links. notably it correctly opens zanthura from `snacks.explorer`)
- buffer width is still fixed

## structure

- `./bin/` -> scripts
- `./lib/` -> `mkNixos` / `mkHome`, the host constructors (exported as `lib`)
- `./modules/home/` -> home-manager modules (exported as `homeModules.default`)
- `./modules/nixos/` -> NixOS modules (exported as `nixosModules.default`)
- `./modules/shared/` -> lists both sides use (fonts, the unfree allow-list)
- `./checks/` -> stand-ins for the flakes that consume dots (`nix flake check`)
- `./templates/` -> project templates, `nix flake init -t`

## hosts

dots defines no machines. A machine is a small flake in its own repo that consumes dots: it calls
`dots.lib.mkNixos` (NixOS plus home-manager) or `dots.lib.mkHome` (standalone home-manager), imports
`dots.nixosModules.default` / `dots.homeModules.default`, and adds only what is specific to it. dots exports
the constructors and module sets, and hosts reuse dots' inputs, so there is a single set of version pins.
Per-host manual setup steps live with the host definitions, not here.

The two module sets are self-contained: they import the upstream modules whose options they set
(DankMaterialShell and its plugin registry, DankSearch, DankCalendar, and stylix on NixOS), so each works
in a plain home-manager or NixOS configuration without the constructors (the `module-sets-*` checks prove
it). The one exception is stylix's home-manager module: on NixOS stylix imports it itself, so
`homeModules.default` leaves it out, `mkHome` adds it for a standalone configuration, and without it the
theme is skipped with a build warning. `dots.checkout` (default `~/dots`) says where the mutable working copy
lives, which the modules that write into it (DMS settings, Claude settings, wallpaper favourites) read.

Every area of a set has a `dots.<area>.enable` switch, so a machine leaves out what it does not want
without `mkForce`: for example `dots.dank.enable = false;` on a laptop without the DMS shell, or
`dots.obsidian.enable = false;`. They are on by default. The areas that were already opt-in (`dots.vscode`,
`dictation`, `flameshot`, `globalprotect`, `repos`, and on NixOS `docker`, `samba`, `torrent`, `waydroid`,
`immich`, `gpuScreenRecorder`) are off by default, as before (`homeModules.default` turns `vscode` on), and
`devlog` is gated by its clone directory.
An area imported on its own (for example `homeModules.shell`) is on, because importing it is the opt-in.
`module-sets-gates` proves the switches: each one does something, and a configuration with every switch off
still evaluates.

To change dots without breaking a machine, test the change against every host before merging (see the
`check` script in the hosts repo).

## formatting

Nix files are formatted with alejandra, declared as the flake's `formatter`: run `nix fmt` (or
`nix fmt <files>`). `nix flake check` fails if any `.nix` file is not formatted. The one-off commit that
formatted the whole repo is listed in `.git-blame-ignore-revs`; to have local `git blame` skip it, run
`git config blame.ignoreRevsFile .git-blame-ignore-revs`.
