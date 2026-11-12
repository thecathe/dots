{
  description = "OCaml project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    # aarch64-darwin is offered on the assumption nothing here is
    # Linux-specific; it is untested. x86_64-darwin is deliberately absent:
    # nixpkgs dropped support for it, and listing it makes
    # `nix flake check --all-systems` fail outright.
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (pkgs: {
      # Used for one step only: writing the *.opam file when the project has
      # none yet (see the shellHook below). dune needs an OCaml compiler just
      # to start, and the opam switch that would supply one is created *from*
      # that file, so this shell brings its own. It stays out of `default` so
      # the everyday shell never carries a second compiler that could be
      # picked up instead of the switch's.
      opam-file = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ocaml dune];
      };

      default = pkgs.mkShell {
        # Nix provides opam and the system libraries that opam packages
        # compile against. OCaml packages themselves, dune included, are
        # managed by opam once a local switch exists.
        nativeBuildInputs = with pkgs; [
          opam
          pkg-config
          git # opam VCS pins, and `dune subst` in the opam build
        ];

        # If an opam package fails to build citing a missing system library,
        # add it here. Common ones are listed below — uncomment as needed.
        buildInputs = with pkgs; [
          # openssl
          # gmp
          # zlib
          # libffi
        ];

        # opam probes for "external dependencies" through the system package
        # manager. On NixOS it finds none and offers to run nix-build for
        # missing libraries — which aborts the bootstrap even though this
        # shell already provides them above. Tell it not to look.
        OPAMNODEPEXTS = "1";

        shellHook = ''
          # opam keeps its state (package index, download cache, a config that
          # records a format version, the list of switches) in a "root". The
          # default root, ~/.opam, is shared by every opam on the machine: the
          # first opam newer than the root upgrades it for good, and any older
          # one then refuses to write to it ("Refusing write access to ~/.opam,
          # which is more recent than this version of opam"). This flake pins
          # its own opam, so the project gets its own root, which only that opam
          # touches, and ~/.opam is left alone. Run from the project root, like
          # the checks below.
          export OPAMROOT="$PWD/.opam-root"

          # --bare: the switch comes from the next step, not from init.
          # --no-setup: don't edit ~/.zshrc and friends; this shell's
          # environment comes from direnv / nix develop, not opam's hooks.
          opam_init='opam init --bare --no-setup --yes'
          bootstrap="$opam_init && opam switch create . --deps-only --yes && opam install . --deps-only --with-dev-setup --yes"
          # The tests below are `find | grep -q .` rather than `ls -- *.opam`:
          # direnv runs this hook in a bash with `nullglob` on, where an
          # unmatched glob expands to nothing, so `ls --` lists the directory
          # and always succeeds, and the "no file" branch is never taken. find
          # takes the pattern itself, so the answer does not depend on shell
          # options, and the same text can be pasted into zsh or bash.
          if ! find . -maxdepth 1 -name '*.opam' | grep -q .; then
            # No .opam file yet: dune writes it from dune-project, and has to
            # run before the switch exists, because the switch is created from
            # that file (its compiler is chosen to satisfy the file's `ocaml`
            # bound; a switch made first would have to guess). The opam-file
            # shell supplies the compiler dune needs for this one step.
            #
            # Success is "the file appeared", not dune's exit status: dune can
            # fail on something that is only missing until the packages below
            # are installed (a library, say), but only after writing the file.
            bootstrap="{ nix develop .#opam-file --command dune build; find . -maxdepth 1 -name '*.opam' | grep -q .; } && $bootstrap"
          elif find . -maxdepth 1 -name '*.opam.locked' | grep -q .; then
            bootstrap="$opam_init && opam switch create . --locked --deps-only --yes && opam install . --locked --deps-only --with-dev-setup --yes"
          fi

          # Test for the binary rather than just _opam/, so a half-built
          # switch is caught too.
          if [ ! -x "$PWD/_opam/bin/dune" ]; then
            if [ -d "$PWD/_opam" ]; then
              # What is there is a half-built switch (an interrupted or failed
              # bootstrap), and the bootstrap cannot run over it: opam refuses
              # to create a switch in a directory that already exists. The
              # directory has to go first, and removing it is enough: opam
              # forgets a local switch whose directory has gone.
              echo "./_opam exists but is incomplete (an interrupted or failed bootstrap)."
              echo "opam will not create a switch over it, so remove it and create it again:"
              bootstrap="rm -rf _opam && $bootstrap"
              prompt='Remove ./_opam and create it again now? this takes a while [y/N] '
            else
              echo "No local opam switch in ./_opam."
              echo "Create it with:"
              prompt='Create it now? this takes a while [y/N] '
            fi
            echo "    $bootstrap"

            # nix-direnv *executes* this hook, and direnv can inherit the
            # terminal's stdin — a bare `read` there would hang every `cd`
            # into the project. direnv sets DIRENV_IN_ENVRC while evaluating
            # .envrc, so only prompt outside it, and only on a tty.
            if [ -z "''${DIRENV_IN_ENVRC:-}" ] && [ -t 0 ]; then
              printf '%s' "$prompt"
              read -r reply
              case "$reply" in
                [yY]*) eval "$bootstrap" ;;
                *) echo "Skipped." ;;
              esac
              unset reply
            else
              echo "Run 'nix develop' for an interactive prompt."
            fi
          fi

          unset bootstrap opam_init prompt
        '';
      };
    });
  };
}
