# dots

## todo

- fix gnome wayland issues, e.g., steamlink fullscreen not capturing
- unpack templates into dots shells and templates that reuse them. allows for more modular project setups e.g., in the case a project uses multiple languages

### nvim

- update nvim to use nvf or nixvim
  - lazynvim with nix stuff? what are the benefits, cos it feels like it may just be compounding the issue of having lots of lua stuff inside of a nix.
- how to do vscode equivalent of `ctrl+shift+up/down` to columnwise select with cursor
- how to configure certain sessions (like vscode workspaces) to show certain hidden directories/files?
- some kind of dictionary/autocorrect?
- auto brackets? (but only in a smart way...)
- picker popup to filter out pdfs? only show them in explorer?
- markdown auto bullet-points
-

## structure

- `./bin/` -> scripts
- `./system/` -> `configuration.nix` programs
- `./modules/` -> home-manager configurations
