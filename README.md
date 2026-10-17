# dots

## todo

- drop the `nixpkgs-firefox` input (`flake.nix`) and the `programs.firefox.package` override (`modules/home/firefox/default.nix`) once the main `nixpkgs` input's Firefox catches up to >=154.0.1 - it was only pinned ahead to fix Outlook/Microsoft-site storage errors on a profile last written by a newer Firefox than nixpkgs had at the time
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
- `./system/` -> `configuration.nix` programs
- `./lib/` -> `mkNixos` / `mkHome`, the host constructors (exported as `lib`)
- `./templates/` -> project templates, `nix flake init -t`
- `./modules/` -> home-manager configurations

## hosts

dots defines no machines. A machine is a small flake in its own repo that consumes dots: it calls
`dots.lib.mkNixos` (NixOS plus home-manager) or `dots.lib.mkHome` (standalone home-manager), imports
`dots.nixosModules.default` / `dots.homeModules.default`, and adds only what is specific to it. dots exports
the constructors and module sets, and hosts reuse dots' inputs, so there is a single set of version pins.
Per-host manual setup steps live with the host definitions, not here.

To change dots without breaking a machine, test the change against every host before merging (see the
`check` script in the hosts repo).
