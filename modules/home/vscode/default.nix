{ lib, pkgs, ... }:
let
  globalExtensions = with pkgs.vscode-extensions; [
    ### essential
    mkhl.direnv
    ### nix
    bbenoist.nix
    kamadorueda.alejandra # fmt
    jnoortheen.nix-ide
    jeff-hykin.better-nix-syntax
    ### md
    yzhang.markdown-all-in-one
    ### useful
    natqe.reload
    christian-kohler.path-intellisense
    # wraith13.zoombar-vscode ## not in pkgs
    ### visuals
    aaron-bond.better-comments
    # amos402.scope-bar ## not in pkgs
    ### theme
    jdinhlife.gruvbox
  ];
  globalSettings = {

    "extensions.autoUpdate" = "on";
    "security.workspace.trust.untrustedFiles" = "open";
    "zenMode.hideLineNumbers" = false;
    "problems.showCurrentInStatus" = true;
    "screencastMode.fontSize" = 64.0;
    "vsintellicode.modify.editor.suggestSelection" = "automaticallyOverrodeDefaultValue";
    "gitHistory.showEditorTitleMenuBarIcons" = false;

    "chat.editor.fontFamily" = "JetBrainsMono Nerd Font Mono";
    "chat.editor.fontSize" = 16.0;
    "chat.fontFamily" = "UbuntuSans Nerd Font";

    "debug.console.fontFamily" = "JetBrainsMono Nerd Font Mono";
    "debug.console.fontSize" = 16.0;

    "markdown.preview.fontFamily" = "UbuntuSans Nerd Font";
    "markdown.preview.fontSize" = 16.0;

    "notebook.showFoldingControls" = "always";
    "notebook.markup.fontFamily" = "UbuntuSans Nerd Font";

    "scm.repositories.sortOrder" = "path";
    "scm.alwaysShowRepositories" = true;
    "scm.inputFontFamily" = "JetBrainsMono Nerd Font Mono";
    "scm.inputFontSize" = 14.857142857142858;

    "wordcounter.simple_wordcount" = false;
    "wordcounter.include_eol_chars" = false;
    "wordcounter.side.left" = [ "word" ];


    "http" = {
      "proxyAuthorization" = null;
      "proxyStrictSSL" = true;
      "proxySupport" = "off";
    };

    "explorer" = {
      "confirmDragAndDrop" = false;
      "confirmDelete" = false;
    };

    "git" = {
      "openRepositoryInParentFolders" = "never";
      "enableSmartCommit" = true;
      "confirmSync" = false;
      "autofetch" = true;
    };

    "diffEditor" = {
      "ignoreTrimWhitespace" = false;
      "maxComputationTime" = 0;
      "useInlineViewWhenSpaceIsLimited" = false;
    };

    "files" = {
      "associations" = {
        "*.dart" = "dart";
        "*.nix" = "nix";
      };
      "exclude" = {
        "**/.classpath" = true;
        "**/.project" = true;
        "**/.settings" = true;
        "**/.factorypath" = true;
      };
    };

    "editor" = {
      "codeActionsOnSave" = {
        "source.fixAll" = "explicit";
        "source.organizeImports" = "never";
      };
      "showFoldingControls" = "always";
      "minimap" = {
        "showSlider" = "always";
        "sectionHeaderFontSize" = 10.285714285714286;
      };
      "mouseWheelZoom" = true;
      "suggestSelection" = "first";
      "formatOnSave" = true;
      "wordWrapColumn" = 72;
      "tabSize" = 2;
      "detectIndentation" = false;
      "foldingStrategy" = "indentation";
      "formatOnPaste" = true;
      "fontFamily" = "JetBrainsMono Nerd Font Mono";
      "fontSize" = 16.0;
      "inlayHints.fontFamily" = "JetBrainsMono Nerd Font Mono";
      "inlineSuggest.fontFamily" = "JetBrainsMono Nerd Font Mono";
    };

    "workbench" = {
      "colorTheme" = "paddy-eucalyptus-upright";

      "editorAssociations" = {
        "*.pdf" = "latex-workshop-pdf-hook";
      };
      "colorCustomizations" = {
        "editorRuler.foreground" = "#4f505a";
      };
      "editor" = {
        "highlightModifiedTabs" = true;
        "scrollToSwitchTabs" = true;
        "wrapTabs" = true;
        "pinnedTabSizing" = "compact";
        "enablePreviewFromCodeNavigation" = true;
        "labelFormat" = "short";
        "untitled.labelFormat" = "name";
        "tabSizing" = "shrink";
        "splitSizing" = "split";
      };
      "settings.applyToAllProfiles" = [
        "editor.tabSize"
        "editor.detectIndentation"
      ];
    };

    "terminal" = {
      "external.linuxExec" = "kitty";

      "integrated" = {
        "fontSize" = 16.0;
        "defaultProfile.windows" = "Git Bash";
        "scrollback" = 10000;

        "profiles.windows" = {
          "PowerShell" = {
            "source" = "PowerShell";
            "icon" = "terminal-powershell";
            "args" = [
              "-ExecutionPolicy"
              "Bypass"
            ];
          };
        };
      };
    };

    "better-comments.tags" = [
      {
        "tag" = "!";
        "color" = "#FF2D00";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "?";
        "color" = "#3498DB";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "//";
        "color" = "#474747";
        "strikethrough" = true;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "todo";
        "color" = "#FF8C00";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "*";
        "color" = "#98C379";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "bug";
        "color" = "#FF5E00";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "hack";
        "color" = "#0062FF";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "fixme";
        "color" = "#FFCC00";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "rewrite";
        "color" = "#FFCC55";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
      {
        "tag" = "~";
        "color" = "#44CCBB";
        "strikethrough" = false;
        "underline" = false;
        "backgroundColor" = "transparent";
        "bold" = false;
        "italic" = false;
      }
    ];
  };
in
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    extensions = globalExtensions;
    profiles =
      builtins.mapAttrs
        (
          name: profileConfig:
          profileConfig
          // {
#            extensions = globalExtensions ++ (profileConfig.extensions or [ ]);
            userSettings = globalSettings // (profileConfig.extensions or { });
          }
        )
        {
          default = {};
          #       "nix" = {
          #         extensions = with pkgs.vscode-extensions; [
          #           bbenoist.nix
          #           kamadorueda.alejandra # fmt
          #           jnoortheen.nix-ide
          #           jeff-hykin.better-nix-syntax
          #         ];
          #       };

          #       "ocaml" = {

          #       };
          #       "erlang" = {

          #       };
          #       "go" = {

          #       };
          #       "python" = {

          #       };
          #       "web" = {

          #       };
          "latex" = {
            userSettings = {
              "[latex]" = {
                "editor" = {
                  "foldingStrategy" = "indentation";
                  "wordWrap" = "wordWrapColumn";
                  "rulers" = [ 72 ];
                  "defaultFormatter" = "James-Yu.latex-workshop";
                };

                "ltex" = {
                  "disabledRules" = {
                    "en-GB" = [ "SENTENCE_WHITESPACE" ];
                  };
                  "enabledRules" = { };

                  "additionalRules.motherTongue" = "en-GB";
                  "language" = "en-GB";
                  "completionEnabled" = true;
                };

                "vslilypond" = {
                  "general.pathToLilypond" = "C:\\Program Files (x86)\\LilyPond\\usr\\bin\\lilypond.exe";
                };

                "latex-workshop" = {

                  "editor.wordWrap" = "on";
                  "view.pdf.zoom" = "page-width";
                  "intellisense.unimathsymbols.enabled" = true;
                  "linting.chktex.convertOutput.column.enabled" = false;
                  "latex" = {
                    "watch.pdf.delay" = 500;
                    "search.rootFiles.exclude" = [ "_*_only.tex" ];
                    "search.rootFiles.include" = [ "main.tex" ];
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
                      "invertMode.grayscale" = 0.2;
                      "invertMode.brightness" = 1.5;
                      "viewer" = "tab";

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
                          "env" = { };
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
                          "env" = { };
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
                          "env" = { };
                        }
                        {
                          "name" = "latexmk_rconly";
                          "command" = "latexmk";
                          "args" = [ "%DOC%" ];
                          "env" = { };
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
                          "env" = { };
                        }
                        {
                          "name" = "bibtex";
                          "command" = "bibtex";
                          "args" = [ "%DOCFILE%" ];
                          "env" = { };
                        }
                        {
                          "name" = "rnw2tex";
                          "command" = "Rscript";
                          "args" = [
                            "-e"
                            "knitr::opts_knit$set(concordance = TRUE); knitr::knit('%DOCFILE_EXT%')"
                          ];
                          "env" = { };
                        }
                        {
                          "name" = "jnw2tex";
                          "command" = "julia";
                          "args" = [
                            "-e"
                            "using Weave; weave(\"%DOC_EXT%\"; doctype=\"tex\")"
                          ];
                          "env" = { };
                        }
                        {
                          "name" = "jnw2texmintex";
                          "command" = "julia";
                          "args" = [
                            "-e"
                            "using Weave; weave(\"%DOC_EXT%\"; doctype=\"texminted\")"
                          ];
                          "env" = { };
                        }
                        {
                          "name" = "tectonic";
                          "command" = "tectonic";
                          "args" = [
                            "--synctex"
                            "--keep-logs"
                            "%DOC%.tex"
                          ];
                          "env" = { };
                        }
                      ];
                    };
                  };
                };
              };
            };
          };

        };
  };
}
