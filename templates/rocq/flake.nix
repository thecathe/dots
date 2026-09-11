{
  description = "Rocq project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
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
    in
    {
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
            bootstrap='opam switch create . --deps-only --yes && opam install . --deps-only --with-dev-setup --yes'
            if ! ls -- *.opam >/dev/null 2>&1; then
              bootstrap="dune build && $bootstrap"
            elif ls -- *.opam.locked >/dev/null 2>&1; then
              bootstrap='opam switch create . --locked --deps-only --yes && opam install . --locked --deps-only --with-dev-setup --yes'
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

            unset bootstrap
          '';
        };
      });
    };
}
