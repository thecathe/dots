{pkgs, ...}: {
  extensions =
    [
      pkgs.vscode-extensions.james-yu.latex-workshop
    ]
    ++ [pkgs.nix-vscode-extensions.vscode-marketplace-release-universal.phr0s.bib];
  settings = {
    "[latex]" = {
      "editor" = {
        "foldingStrategy" = "indentation";
        "wordWrap" = "wordWrapColumn";
        "wordWrapColumn" = 72;
        "rulers" = [72];
        "defaultFormatter" = "James-Yu.latex-workshop";
      };
    };
    "workbench" = {
      "editorAssociations" = {
        "*.pdf" = "latex-workshop-pdf-hook";
      };
    };
    "latex-workshop" = {
      "editor.wordWrap" = "on";
      "intellisense.unimathsymbols.enabled" = true;
      "linting.chktex.convertOutput.column.enabled" = false;
      "latex" = {
        "watch.pdf.delay" = 500;
        "search.rootFiles.exclude" = ["_*_only.tex"];
        "search.rootFiles.include" = ["main.tex"];
        "tools" = [
          {
            "name" = "tectonic";
            "command" = "tectonic";
            "args" = [
              "--synctex"
              "--keep-logs"
              "%DOC%.tex"
            ];
            "env" = {};
          }
          {
            # both need the `latex-texlive` template's devShell active (real
            # texlive) — not available from the global tectonic-only install
            "name" = "latexmk";
            "command" = "latexmk";
            "args" = [
              "-shell-escape"
              "-synctex=1"
              "-interaction=nonstopmode"
              "-file-line-error"
              "-pdf"
              "-outdir=%OUTDIR%"
              "%DOC%"
            ];
            "env" = {};
          }
          {
            "name" = "lualatexmk";
            "command" = "latexmk";
            "args" = [
              "-synctex=1"
              "-interaction=nonstopmode"
              "-file-line-error"
              "-lualatex"
              "-outdir=%OUTDIR%"
              "%DOC%"
            ];
            "env" = {};
          }
        ];
        "recipes" = [
          {
            "name" = "tectonic";
            "tools" = ["tectonic"];
          }
          {
            "name" = "latexmk";
            "tools" = ["latexmk"];
          }
          {
            "name" = "lualatexmk";
            "tools" = ["lualatexmk"];
          }
        ];
      };
      "view" = {
        "outline.sections" = [
          "part"
          "chapter"
          "section"
          "subsection"
          "subsubsection"
          "paragraph"
        ];
        "pdf" = {
          "trim" = 3;
          "viewer" = "tab";
          "zoom" = "page-width";
          "invertMode" = {
            "grayscale" = 0.2;
            "brightness" = 1.5;
          };
        };
      };
    };
  };
}
