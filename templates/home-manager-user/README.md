# home-manager-user template

A standalone home-manager flake for a new user on a shared NixOS host (e.g.
`nixos-laptop`). It's fully independent of `thecathe/dots` - no shared
modules, no shared identity - so it works the same whether you keep it here
or move it to your own repo.

## Setup

1. Scaffold it into a new directory:

   ```sh
   mkdir my-dots && cd my-dots
   nix flake init -t github:thecathe/dots#home-manager-user
   ```

2. Edit `flake.nix` and `home.nix`, replacing every `NEW_USER`/`NEW_HOST`
   with your actual Linux username and the hostname of the machine you're
   setting up (e.g. `max`/`nixos-laptop`). Set your own `git` name/email in
   `home.nix`, and add/remove packages and other home-manager options as you
   like.

3. Push it to your own GitHub repo, and add your own SSH key to your own
   GitHub account.

4. Apply it, from your own account on the machine:

   ```sh
   nix run home-manager/master -- switch --flake .#<you>@<host>
   # or, once pushed:
   nix run home-manager/master -- switch --flake github:<you>/<your-repo>#<you>@<host>
   ```

   No package needs installing first - flakes are already enabled system-wide.

5. Re-run the same `switch` command any time you want to apply changes. This
   never touches the system-level (`sudo nixos-rebuild`) configuration, and
   the person who manages that config never needs to touch your repo either.
