{
  description = "Haskell project";

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
        # Nix provides GHC, cabal-install and HLS. Unlike opam, cabal's own
        # "Nix-style local builds" (the default since cabal-install >=2.4)
        # need no local "switch" to create first -- `cabal build`/`cabal
        # run` work immediately once these are on PATH, managing
        # dist-newstyle/ and the global ~/.cabal/store transparently. So
        # there's no shellHook bootstrap dance here, unlike
        # templates/ocaml and templates/rocq.
        nativeBuildInputs = with pkgs; [
          ghc
          cabal-install # on a brand new machine, run `cabal update` once to
                        # fetch the Hackage package index before the first
                        # `cabal build`
          haskell-language-server
          pkg-config # only exercised by Hackage packages with a
                     # pkgconfig-depends: stanza (e.g. zlib, text-icu)
          git # needed if cabal.project ever pins a dependency via a
              # source-repository-package stanza
        ];

        # If a Hackage package fails to build citing a missing system
        # library, add it here. Commented starting points for common ones:
        buildInputs = with pkgs; [
          # zlib
          # openssl
          # pcre
        ];
      };
    });
  };
}
