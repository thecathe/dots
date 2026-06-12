# dots

## todo

- fix gnome wayland issues, e.g., steamlink fullscreen not capturing
- unpack templates into dots shells and templates that reuse them. allows for more modular project setups e.g., in the case a project uses multiple languages

### nvim

- update nvim to use nvf or nixvim
  - lazynvim with nix stuff? what are the benefits, cos it feels like it may just be compounding the issue of having lots of lua stuff inside of a nix.
- stop focusing explorer on tab close, move to next tab
- why does `.md` default to tab sizes of 2?
- how to get behaviour of `shift-tab` to unindent things
  - how to unindent multiple lines?
  - how to do vscode equivalent of `ctrl+shift+up/down` to columnwise select with cursor
- how to configure certain sessions (like vscode workspaces) to show certain hidden directories/files?
- git integration
  - "gutter" indicators for changes
  - more convenient alternative to `\t` -> `git add . && git commit -m "..."`
- some kind of dictionary/autocorrect?
- auto brackets? (but only in a smart way...)

## structure

- `./bin/` -> scripts
- `./system/` -> `configuration.nix` programs
- `./modules/` -> home-manager configurations
