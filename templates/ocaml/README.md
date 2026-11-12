# Readme


## Setup

### Setup direnv

```
direnv allow .
```

This will ensure your shell has the necessary tools installed when entering this directory.

### Generate the `.opam` file (first time only)

If the project root already has a `*.opam` file, skip this step. Otherwise:

```
nix develop .#opam-file --command dune build
```

`dune` writes `my-project.opam` from `dune-project` (see `generate_opam_files`). It needs an OCaml compiler just to start, and the opam switch in the next step is created *from* that file, so this step runs in a small separate dev shell (`opam-file` in `flake.nix`) that brings a compiler for this one command. Doing it first matters: the switch's OCaml version is chosen to satisfy the `ocaml` bound in the `.opam` file, which a switch made earlier could only guess.

> Note: it is crucial that this file is tracked by git so that you can skip this step when next setting up this project on a new directory.

### Create local opam switch

```
opam init --bare --no-setup --yes
opam switch create . --locked --deps-only --yes
```

The first command creates this project's own opam root in `./.opam-root` (see [Additional Notes](#additional-notes)); it is quick and only needed once per clone. The second creates a local opam switch, which the direnv `.envrc` will automatically use upon entering the directory.

Run these inside the dev shell (direnv, or `nix develop`): it is what points `opam` at the project's root.

> Note: after this step you may need to kill your terminal (`ctrl+d`) and reopen a new one. Alternatively, run `direnv reload`.

### Install opam packages

```
opam install . --locked --deps-only --with-dev-setup --yes
```

This installs all the packages listed in `dune-project`, including those marked as `:with-dev-setup`. Since we are using nix, at a certain point you'll likely reach the following screen:

```
<><> Handling external dependencies <><><><><><><><><><><><><><><><><><><><><><>

opam believes some required external dependencies are missing. opam can:
> 1. Run nix-build to install them (may need root/sudo access)
  2. Display the recommended nix-build command and wait while you run it manually (e.g. in another terminal)
  3. Continue anyway, and, upon success, permanently register that this external dependency is present, but not detectable
  4. Abort the installation

[1/2/3/4]
```

Go ahead with option `1` and wait for it to finish.

### Additional Notes

**Why the project has its own opam root.** opam keeps its state (the package index, a download cache, and the list of switches) in a *root*, by default `~/.opam`, shared by every opam on the machine. The root records a format version: the first opam newer than the root upgrades it for good, and any older opam then refuses to write to it (`Refusing write access to ~/.opam, which is more recent than this version of opam`). This project's flake pins its own opam, so the dev shell sets `OPAMROOT` to `./.opam-root` (git-ignored), a root that only that opam ever touches; your `~/.opam` is left alone, and so are other people's. Running `opam` outside the dev shell uses `~/.opam` as usual.

**Shell config.** `opam init` normally offers to edit `~/.bashrc`/`~/.zshrc`. The `--no-setup` flag above stops that, which matters if your shell config is managed by `nix`: any such edits would be clobbered at your next rebuild. The environment comes from direnv instead (`.envrc` runs `opam env`).