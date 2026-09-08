{
  description = "LaTeX project needing real texlive (packages outside Tectonic's bundle, LuaTeX, etc.)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [
        (pkgs.texliveSmall.withPackages (ps: [
          ps.latexmk # engines (lualatex/pdflatex/xelatex) + bibtex are already in the small base
          # add more `ps.<package>` here as your project actually needs them
        ]))
      ];
    };
  };
}
