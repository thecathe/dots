{
  description = "Rocq project";

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
        # compile against. OCaml/Rocq packages themselves, dune included, are
        # managed by opam once a local switch exists.
        nativeBuildInputs = with pkgs; [
          opam
          pkg-config
          git # opam VCS pins, and `dune subst` in the opam build
          gnumake # rocq-core's own opam build uses a Makefile
        ];

        # If an opam package fails to build citing a missing system library,
        # add it here. gmp and zlib are required by rocq-core's dependency
        # chain (zarith -> conf-gmp, conf-zlib); the rest are commented
        # starting points.
        buildInputs = with pkgs; [
          gmp
          zlib
          # openssl
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

          # Most community Rocq packages (equations, mathcomp, stdpp, ...)
          # aren't in the default opam.ocaml.org repo -- only rocq-core/
          # rocq-stdlib/rocq-runtime etc. are. Registering rocq-released
          # here means it's available from the very first switch creation,
          # on this machine or a fresh clone on another one, without an
          # extra manual step. `opam repo add` needs a switch to attach to,
          # so this is done via `opam switch create`'s own --repositories
          # flag instead, which registers *and* selects it atomically (in
          # this project's own root).
          rocq_repos='default,rocq-released=https://rocq-prover.org/opam/released'
          bootstrap="$opam_init && opam switch create . --repositories=$rocq_repos --deps-only --yes && opam install . --deps-only --with-dev-setup --yes"
          # The tests below are `find | grep -q .` rather than `ls -- *.opam`:
          # direnv runs this hook in a bash with `nullglob` on, where an
          # unmatched glob expands to nothing, so `ls --` lists the directory
          # and always succeeds, and the "no file" branch is never taken. find
          # takes the pattern itself, so the answer does not depend on shell
          # options, and the same text can be pasted into zsh or bash.
          note=
          if ! find . -maxdepth 1 -name '*.opam' | grep -q .; then
            # No .opam file yet: dune writes it from dune-project, and has to
            # run before the switch exists, because the switch is created from
            # that file (its compiler is chosen to satisfy the file's `ocaml`
            # bound; a switch made first would have to guess). The opam-file
            # shell supplies the compiler dune needs for this one step.
            #
            # Success is "the file appeared", not dune's exit status, and here
            # that matters: dune stops on "Program rocq not found" (rocq is
            # one of the packages the switch is about to install) but only
            # after writing the file.
            bootstrap="{ nix develop .#opam-file --command dune build; find . -maxdepth 1 -name '*.opam' | grep -q .; } && $bootstrap"
            note="(Expect dune to report 'Program rocq not found' on the way: rocq is installed by a later step, and the .opam file is written regardless.)"
          elif find . -maxdepth 1 -name '*.opam.locked' | grep -q .; then
            bootstrap="$opam_init && opam switch create . --repositories=$rocq_repos --locked --deps-only --yes && opam install . --locked --deps-only --with-dev-setup --yes"
          fi

          # Test for the binary rather than just _opam/, so a half-built
          # switch is caught too.
          if [ ! -x "$PWD/_opam/bin/rocq" ]; then
            echo "No local opam switch in ./_opam (or it is incomplete)."
            echo "Create it with:"
            echo "    $bootstrap"
            [ -n "$note" ] && echo "$note"

            # nix-direnv *executes* this hook, and direnv can inherit the
            # terminal's stdin — a bare `read` there would hang every `cd`
            # into the project. direnv sets DIRENV_IN_ENVRC while evaluating
            # .envrc, so only prompt outside it, and only on a tty.
            if [ -z "''${DIRENV_IN_ENVRC:-}" ] && [ -t 0 ]; then
              printf 'Create it now? this takes a while [y/N] '
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

          unset bootstrap opam_init rocq_repos note
        '';
      };
    });
  };
}
