# host-nixos template

A NixOS machine that consumes dots: `dots.lib.mkNixos` wires in NixOS, home-manager and the shared
modules, so this flake holds only what is specific to the machine. For a machine that doesn't run NixOS,
use the `host-home` template instead.

## Setup

1. Scaffold it into the repo (or directory) that holds your machines:

   ```sh
   mkdir NEW_HOST && cd NEW_HOST
   nix flake init -t github:thecathe/dots#host-nixos
   ```

2. Replace every `NEW_HOST` and `NEW_USER` (in `flake.nix`, `configuration.nix` and `home.nix`) with the
   machine's hostname and your username.

3. On the machine, generate its hardware configuration next to `flake.nix`:

   ```sh
   nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

   With flakes, nix only sees files git tracks, so `git add` the new files before building.

4. Link the dots checkout to `~/dots`, where dots' scripts expect it, then apply:

   ```sh
   sudo nixos-rebuild switch --flake .#NEW_HOST
   ```

`flake.lock` pins dots, and through it every other input. Update it deliberately with
`nix flake update dots`.
