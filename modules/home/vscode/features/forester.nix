{pkgs, ...}: let
  # Pinned to an explicit marketplace version+hash, rather than
  # pkgs.nix-vscode-extensions...kaierikniermann.forest-keeper, which always
  # resolves to whatever version happens to be cached in that flake input's
  # daily-refreshed snapshot. The patch below targets exact string literals
  # inside this version's *compiled* JS; an unpinned reference could silently
  # pick up a newer forest-keeper build on a future `nix flake update` whose
  # minified output no longer matches those literals, breaking the patch
  # without any obvious error. Bump the version/hash here deliberately when
  # actually upgrading, so that's a conscious, re-verified step.
  #
  # forest-keeper's compiled LTeX integration hardcodes the extension ID
  # "valentjn.vscode-ltex" (both in out/languageToolIntegration.js and the
  # bundled out/extension.js) to find-and-force-activate the LTeX companion,
  # bypassing that extension's own activationEvents entirely. We run
  # ltex-plus.vscode-ltex-plus instead (the actively maintained fork, see
  # modules/home/vscode/features/languagetool.nix), so patch forest-keeper's
  # compiled JS to look for that ID instead, keeping the enable-prompt,
  # auto-trigger-on-open/save and "Check All Tree Files" command working.
  forestKeeper =
    (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        publisher = "KaiErikNiermann";
        name = "forest-keeper";
        version = "0.4.17";
        hash = "sha256-VYdoEHWbSO2nABtCKEXuektljnxx32O/5IXvEImHDmU=";
      };
    }).overrideAttrs
    (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace out/languageToolIntegration.js out/extension.js \
            --replace-fail 'valentjn.vscode-ltex' 'ltex-plus.vscode-ltex-plus'
        '';
    });
in {
  extensions = [
    forestKeeper
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
      "editor.formatOnPaste" = false;
      "editor.defaultFormatter" = "KaiErikNiermann.forest-keeper";
    };
  };
}
