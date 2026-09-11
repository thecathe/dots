{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    opam
    gcc
    gnumake
    pkg-config
    m4 # needed to build ocaml-base-compiler from source
    gnutar
    gzip
    xz
    bzip2
    unzip
    patch
    diffutils
    gawk
  ];

  # Standalone opam switch, not tied to any project, used as opam's global
  # default fallback (e.g. what VSCode's OCaml Platform / dune-format falls
  # back to outside a project-local switch). Self-heals: if the switch is
  # missing OR its dune binary is broken (e.g. a prior switch's binaries
  # were nix-store-linked and got GC'd), it's wiped and rebuilt using the
  # gcc/opam provided above from the persistent home-manager profile
  # (GC-rooted), instead of a transient per-project devShell.
  home.activation.opamGlobalSwitch = let
    # opam shells out to tar/gcc/make/etc while building the compiler+dune.
    # The activation script runs with home-manager's own internal PATH, not
    # the home.packages profile (that's only wired into interactive shell
    # PATH afterwards), so opam's subprocesses need these put on PATH
    # explicitly here rather than relying on the packages above being found.
    opamBuildPath = lib.makeBinPath (with pkgs; [
      coreutils
      gcc
      gnumake
      pkg-config
      m4
      gnutar
      gzip
      xz
      bzip2
      unzip
      patch
      diffutils
      gawk
    ]);
  in
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      opam="${pkgs.opam}/bin/opam"
      opamroot="$HOME/.opam"
      export PATH="${opamBuildPath}:$PATH"
      # opam's system depext probing (e.g. via apt-cache) isn't available in
      # the activation script's PATH and isn't needed here (nix provides the
      # real toolchain above). See templates/ocaml/flake.nix for precedent.
      export OPAMNODEPEXTS=1

      # opam's build sandbox shells out to a plain `bwrap` looked up on PATH.
      # Without this, PATH here resolves to nixpkgs' generic bubblewrap
      # (pulled in transitively, no matching AppArmor profile on this host),
      # which fails setting up the sandbox's loopback interface under
      # Ubuntu's unprivileged-userns hardening ("bwrap: loopback: Failed
      # RTM_NEWADDR: Operation not permitted") - whereas the apt-installed
      # /usr/bin/bwrap has a matching profile (/etc/apparmor.d/bwrap) and
      # works fine. Shim just that one binary ahead of PATH so opam picks up
      # the system bwrap specifically, without reordering anything else.
      # No-ops (falls through to whatever bwrap is already on PATH) on hosts
      # without /usr/bin/bwrap, e.g. the NixOS host.
      if [ -x /usr/bin/bwrap ]; then
        bwrapShim="$(mktemp -d)"
        ln -sf /usr/bin/bwrap "$bwrapShim/bwrap"
        export PATH="$bwrapShim:$PATH"
      fi

      if [ ! -e "$opamroot/config" ]; then
        $opam init --bare --yes
      fi

      if ! "$opamroot/home/bin/dune" --version >/dev/null 2>&1; then
        $opam switch remove home --yes 2>/dev/null || true
        $opam switch create home ocaml-base-compiler --yes
        $opam install dune --switch=home --yes
      fi

      $opam switch set home
    '';
}
