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
- `./modules/` -> home-manager configurations

## manual setup (non-nix)

Steps needed on hosts that can't be captured by home-manager/NixOS config, e.g. because they touch root-owned files outside home-manager's reach (standalone home-manager has no `/etc` management).

- `worklaptop` (ubuntu, standalone home-manager): swaylock must be installed via apt, not Nix. `programs.swaylock.package` is forced to `null` for this host (`hosts/worklaptop/modules/wm/niri.nix`, following home-manager's own documented recommendation for this exact case) because the Nix-built swaylock links against Nix's own linux-pam, which can never authenticate on a non-NixOS host - its `pam_unix.so` needs a setuid-root `unix_chkpwd` helper to read `/etc/shadow`, and Nix doesn't ship setuid binaries in the store (only NixOS's `security.wrappers` provides that). It doesn't error, it just silently rejects every password, correct or not - and if you kill the stuck lock client instead of unlocking properly, niri's session-lock protocol keeps the whole session locked (solid red screen) until that specific niri process is killed and a fresh one starts. `enable` stays `true` so Stylix still themes `~/.config/swaylock/config`; only the package (and its PATH-shadowing symlink) is dropped, so PATH falls through to apt's binary, which reads the same config file. Recreate by hand after reprovisioning:
  ```
  sudo apt install swaylock
  ```
  This also installs `/etc/pam.d/swaylock` (`auth include login`), which apt manages automatically from here on.
