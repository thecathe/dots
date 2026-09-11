{
  description = "LaTeX project needing real texlive (packages outside Tectonic's bundle, LuaTeX, etc.)";

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
        buildInputs = [
          (pkgs.texliveSmall.withPackages (ps: [
            ps.latexmk # engines (lualatex/pdflatex/xelatex) + bibtex are already in the small base
            # add more `ps.<package>` here as your project actually needs them
          ]))
        ];
      };
    });
  };
}
