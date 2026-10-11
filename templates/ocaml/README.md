# Readme


## Setup

### Setup direnv

```
direnv allow .
```

This will ensure your shell has the necessary tools installed when entering this directory.

### Create local opam switch

```
opam switch create . --locked --deps-only --yes
```

This will create a local opam switch, which the direnv `.envrc` will automatically use upon entering the directory.

> Note: after this step you may need to kill your terminal (`ctrl+d`) and reopen a new one. Alternatively, run `direnv reload`.

#### Conditional step: is there a `.opam` file?

If there is, then skip this step and continue to the [next](#install-opam-packages). Otherwise, we need to do some first-time-setup:

```
opam install dune --yes
```

will install the `dune` project management system for OCaml projects. Then run

```
dune build
```

this will create the `*.opam` file in the project root.

> Note: it is crucial that this file is tracked by git so that you can skip this step when next setting up this project on a new directory.

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

You may be prompted to run `opam init` before being able to do the other `opam` commands. Follow through with `opam init` and then proceed with the `opam` commands above. Note that if your `bash`/`zsh` is managed by `nix` then any modifications `opam init` makes to `~/.bashrc`/`~/.zshrc` will be clobbered when you next rebuild, so worth picking the option where you'll run `eval $(opam env)` manually and go sort it out yourself.