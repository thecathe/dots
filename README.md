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

To change dots without breaking a machine, test the change against every host before merging (see the
`check` script in the hosts repo).

## formatting

Nix files are formatted with alejandra, declared as the flake's `formatter`: run `nix fmt` (or
`nix fmt <files>`). `nix flake check` fails if any `.nix` file is not formatted. The one-off commit that
formatted the whole repo is listed in `.git-blame-ignore-revs`; to have local `git blame` skip it, run
`git config blame.ignoreRevsFile .git-blame-ignore-revs`.
