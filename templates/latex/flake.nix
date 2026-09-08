{
  description = "LaTeX project (Tectonic)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    # Files needed by your document that aren't in Tectonic's bundle *and*
    # aren't packaged in texlive either (e.g. CTAN packages TeX Live
    # excludes, like `emerald`). Tectonic searches the working directory for
    # inputs, so fetching them here and symlinking them in via shellHook
    # makes them resolve without switching to the `latex-texlive` template.
    # If you populate this, switch .envrc below to plain `use flake` — see
    # its comment for why. `name` is the exact filename your document
    # expects (not the fetched derivation's own store name) — the shellHook
    # also keeps it out of git via an exact (non-wildcard) .gitignore entry.
    # Example:
    #
    # extraTexFiles = [
    #   {
    #     name = "emerald.sty";
    #     src = pkgs.fetchurl {
    #       url = "https://tug.ctan.org/fonts/emerald/tex/latex/emerald/emerald.sty";
    #       sha256 = "..."; # fill in via `nix store prefetch-file <url>`
    #     };
    #   }
    # ];
    #
    # For a multi-file CTAN package, use `pkgs.fetchzip` for `src` and
    # symlink its whole output directory (or the specific files within it)
    # rather than a single fetchurl per file.
    extraTexFiles = [];
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [pkgs.tectonic];
      shellHook = builtins.concatStringsSep "\n" (map (f: ''
        ln -sf ${f.src} ./${f.name}
        grep -qxF '${f.name}' .gitignore 2>/dev/null || echo '${f.name}' >> .gitignore
      '') extraTexFiles);
    };
  };
}
