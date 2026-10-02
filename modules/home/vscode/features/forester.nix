{pkgs, ...}: {
  extensions = with pkgs.vscode-extensions; [
    pkgs.nix-vscode-extensions.vscode-marketplace-release-universal.kaierikniermann.forest-keeper
  ];
  settings = {
    "forester.completion.showID" = true;
    "forester.config" = ""; # should be edited per workspace, instead of globally
    "forester.create.author" = "cathe";
    "forester.create.openNewTreeMode" = "active";
    "forester.create.random" = true;
    "forester.formatter.autoScanMacros" = true;
    "forester.formatter.ignoredCommands" = ["meta" "taxon"];
    "forester.graphView.excludedNodes" = [
      "basic-macros"
    ];
    "forester.hover.latex.enabled" = true;
    "forester.hover.latex.preambleMacro" = "";
    "forester.hover.latex.texInputs" = [];
    "forester.hover.latex.useProjectPreamble" = true;
    "forester.inlayHints.paramNames.enabled" = false;
    "forester.inlayHints.tagClosures.enabled" = true;
    "forester.inlayHints.tagClosures.tags" = [
      "ol"
      "ul"
      "li"
      "p"
      "subtree"
      "##"
      "tex"
      "texmath"
      "solution"
    ];
    "forester.languageTool.enable" = false;
    "forester.languageTool.javaOpts" = "";
    "forester.languageTool.language" = "en";
    "forester.path" = "forester";
    "forester.taxonCustomization" = {};
    "[forester]" = {
      "editor.wordWrap" = "on";
      "editor.tabSize" = 2;
      "editor.wordBasedSuggestions" = "off";
      "editor.formatOnSave" = false;
      "editor.defaultFormatter" = "KaiErikNiermann.forest-keeper";
    };
  };
}
