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
      "latex-workshop" = {
        "editor.wordWrap" = "on";
        "intellisense.unimathsymbols.enabled" = true;
        "linting.chktex.convertOutput.column.enabled" = false;
        "latex" = {
          "watch.pdf.delay" = 500;
          "search.rootFiles.exclude" = ["_*_only.tex"];
          "search.rootFiles.include" = ["main.tex"];
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

          "latex.tools" = [
            {
              "name" = "latexmk";
              "command" = "latexmk";
              "args" = [
                # "-bibtex";
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
            {
              "name" = "xelatexmk";
              "command" = "latexmk";
              "args" = [
                "-synctex=1"
                "-interaction=nonstopmode"
                "-file-line-error"
                "-xelatex"
                "-outdir=%OUTDIR%"
                "%DOC%"
              ];
              "env" = {};
            }
            {
              "name" = "latexmk_rconly";
              "command" = "latexmk";
              "args" = ["%DOC%"];
              "env" = {};
            }
            {
              "name" = "pdflatex";
              "command" = "pdflatex";
              "args" = [
                "-synctex=1"
                "-interaction=nonstopmode"
                "-file-line-error"
                "%DOC%"
              ];
              "env" = {};
            }
            {
              "name" = "bibtex";
              "command" = "bibtex";
              "args" = ["%DOCFILE%"];
              "env" = {};
            }
            {
              "name" = "rnw2tex";
              "command" = "Rscript";
              "args" = [
                "-e"
                "knitr::opts_knit$set(concordance = TRUE); knitr::knit('%DOCFILE_EXT%')"
              ];
              "env" = {};
            }
            {
              "name" = "jnw2tex";
              "command" = "julia";
              "args" = [
                "-e"
                "using Weave; weave(\"%DOC_EXT%\"; doctype=\"tex\")"
              ];
              "env" = {};
            }
            {
              "name" = "jnw2texmintex";
              "command" = "julia";
              "args" = [
                "-e"
                "using Weave; weave(\"%DOC_EXT%\"; doctype=\"texminted\")"
              ];
              "env" = {};
            }
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
          ];
        };
      };
    };
  };
}
