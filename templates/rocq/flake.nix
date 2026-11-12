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
      default = pkgs.mkShell {
        # Nix provides opam and the system libraries that opam packages
        # compile against. OCaml/Rocq packages themselves are managed by
        # opam once a local switch exists.
        nativeBuildInputs = with pkgs; [
          opam
          dune # bootstraps *.opam generation before a switch exists; opam's
          # own `dune` dependency takes over via PATH once one does
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
          if ! find . -maxdepth 1 -name '*.opam' | grep -q .; then
            bootstrap="dune build && $bootstrap"
          elif find . -maxdepth 1 -name '*.opam.locked' | grep -q .; then
            bootstrap="$opam_init && opam switch create . --repositories=$rocq_repos --locked --deps-only --yes && opam install . --locked --deps-only --with-dev-setup --yes"
          fi

          # Test for the binary rather than just _opam/, so a half-built
          # switch is caught too.
          if [ ! -x "$PWD/_opam/bin/rocq" ]; then
            echo "No local opam switch in ./_opam (or it is incomplete)."
            echo "Create it with:"
            echo "    $bootstrap"

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

          unset bootstrap opam_init rocq_repos
        '';
      };
    });
  };
}
