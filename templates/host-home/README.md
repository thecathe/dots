# host-home template

A machine that doesn't run NixOS (e.g. Ubuntu with nix installed): standalone home-manager through
`dots.lib.mkHome`, with dots' shared home modules. For a NixOS machine, use the `host-nixos` template
instead. For a second user on someone else's machine who wants nothing of dots, use
`home-manager-user`.

## Setup

1. Install nix with flakes enabled, then scaffold the template into the repo (or directory) that holds
   your machines:

   ```sh
   mkdir NEW_HOST && cd NEW_HOST
   nix flake init -t github:thecathe/dots#host-home
   ```

2. Replace every `NEW_HOST` and `NEW_USER` (in `flake.nix` and `home.nix`) with the machine's hostname
   and your username. With flakes, nix only sees files git tracks, so `git add` them.

3. Link the dots checkout to `~/dots`, where dots' scripts expect it, then apply:

   ```sh
   nix run home-manager/master -- switch --flake .#NEW_USER@NEW_HOST
   ```

   From then on `home-manager switch --flake .#NEW_USER@NEW_HOST` is enough.

Some things home-manager can't do outside NixOS, and they need doing by hand on the machine:

- Graphical programs built by nix can't find the distribution's GPU drivers. Wrap them with
  [nixGL](https://github.com/nix-community/nixGL) (dots has it as the `nixgl` input).
- A login-screen session (e.g. niri) needs a `.desktop` file in `/usr/share/wayland-sessions/`, which only
  root can write.
- Programs that check passwords through PAM (screen lockers) need the distribution's own build, since nix
  can't ship setuid helpers.
