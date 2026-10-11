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
  #
  # forest-keeper's "New Tree" also insists on a non-empty prefix: with
  # forester.defaultPrefix = "" it prompts for one, and an empty answer or
  # Escape silently cancels, so there is no way to create an unprefixed tree
  # (`forester new --random` with no `--prefix`, as the CLI allows). Patch
  # three spots in out/extension.js so that an empty defaultPrefix means "no
  # prefix": return it without prompting, treat only `undefined` (a real
  # cancel) as an abort, and omit `--prefix` entirely when it is empty. It is
  # omitted rather than passed as "" because forester's id allocator treats
  # `Some ""` as a different namespace from the unprefixed trees, which would
  # skip its collision check against them. The minified identifiers (vC, i, y)
  # are specific to 0.4.17; --replace-fail makes a version bump fail loudly.
  #
  # The stock "New Tree" always asks for a title and refuses an empty one.
  # Add a second command, forester.newTreeUntitled, that runs the same flow
  # with the title prompt skipped (the tree gets \date and \author only), via
  # a `noTitle` option on createNewTree (qC) threaded through the command
  # wrapper (ag). forester.newTree itself is left as is, so the two can be
  # bound separately (see keybindings below).
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

          substituteInPlace out/extension.js \
            --replace-fail 'defaultPrefix");if(e)return e;' 'defaultPrefix");if(e!==void 0)return e;' \
            --replace-fail 'await vC();if(!i)return;' 'await vC();if(i===void 0)return;' \
            --replace-fail '"--prefix",i,...y?' '...i?["--prefix",i]:[],...y?'

          substituteInPlace out/extension.js \
            --replace-fail 'let o=await MC({prompt:"Enter title for the new tree' 'let o=t.noTitle?{taxon:void 0,title:void 0}:await MC({prompt:"Enter title for the new tree' \
            --replace-fail 'async function ag(t,e){let n=await qC({destFolder:t,fromTemplate:e});' 'async function ag(t,e,u){let n=await qC({destFolder:t,fromTemplate:e,noTitle:u});' \
            --replace-fail '$.commands.registerCommand("forester.newTree",b=>ag(b,!1)),' '$.commands.registerCommand("forester.newTree",b=>ag(b,!1)),$.commands.registerCommand("forester.newTreeUntitled",b=>ag(b,!1,!0)),'
        '';
    });

  # Local extension (./forester-edit) for structural insertions that need
  # buffer-level brace matching and cursor placement, which built-in commands
  # and the on-disk touch_date.py task can't do. Bound in keybindings below.
  forestEdit = pkgs.vscode-utils.buildVscodeExtension {
    pname = "forester-edit";
    version = "0.1.0";
    # named "extension" because buildVscodeExtension expects that source root
    src = builtins.path {
      path = ./forester-edit;
      name = "extension";
    };
    vscodeExtPublisher = "thecathe";
    vscodeExtName = "forester-edit";
    vscodeExtUniqueId = "thecathe.forester-edit";
  };
in {
  extensions = [
    forestKeeper
    forestEdit
  ];
  settings = {
    "forester.completion.showID" = true;
    "forester.config" = ""; # should be edited per workspace, instead of globally
    # No global author: new trees get theirs from `[forest.new] author` in each
    # project's forest.toml (written by the forester fork's `forester new`).
    # forest-keeper only falls back to forester.create.author when no \author
    # is present, so leaving it unset avoids a stray, differently-spelled one.
    "forester.create.openNewTreeMode" = "active";
    "forester.create.random" = true;
    "forester.decorations.enabled" = true;
    "forester.defaultPrefix" = "";
    "forester.defaultTemplate" = "(No template)";
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
    # forest-keeper registers two definition providers for the same link (its
    # own client-side one, plus the bundled Langium language server's, which
    # deliberately points at a different location "so Peek shows meaningful
    # content") - two locations for one symbol is what makes VS Code default
    # to the Peek overlay on Ctrl+click instead of jumping straight there.
    "editor.gotoLocation.multipleDefinitions" = "goto";
    "editor.definitionLinkOpensInPeek" = false; # already VS Code's default; explicit for clarity
    "[forester]" = {
      "editor.wordWrap" = "on";
      "editor.tabSize" = 2;
      "editor.wordBasedSuggestions" = "off";
      "editor.formatOnSave" = false;
      "editor.formatOnPaste" = false;
      "editor.defaultFormatter" = "KaiErikNiermann.forest-keeper";
      # forest-keeper's language-configuration.json treats every "{"..."}" pair as a
      # folding region (not just block macros), so VS Code's minimap region-header
      # feature renders each macro name (e.g. \meta, \p) as an oversized header in
      # the minimap, clipped by the tiny per-line height. Suppress it for .tree files.
      "editor.minimap.showRegionSectionHeaders" = false;
    };
  };
  keybindings = [
    {
      key = "ctrl+shift+d";
      command = "runCommands";
      when = "editorTextFocus && resourceExtname == '.tree'";
      args.commands = [
        "workbench.action.files.save"
        {
          command = "workbench.action.tasks.runTask";
          args = "Forester: Touch Date";
        }
      ];
    }
    {
      key = "shift+alt+r";
      command = "forester.refreshTreeView";
      when = "editorTextFocus && resourceExtname == '.tree'";
    }
    {
      key = "ctrl+alt+shift+r";
      command = "forester.restartLanguageServer";
      when = "editorTextFocus && resourceExtname == '.tree'";
    }
    {
      key = "ctrl+t";
      command = "forester.newTreeUntitled";
      when = "editorTextFocus && resourceExtname == '.tree'";
    }
    # Frees ctrl+shift+t (VS Code's "Reopen Closed Editor") for the titled
    # variant below.
    {
      key = "ctrl+shift+t";
      command = "-workbench.action.reopenClosedEditor";
    }
    {
      key = "ctrl+shift+t";
      command = "forester.newTree";
      when = "editorTextFocus && resourceExtname == '.tree'";
    }
    {
      key = "ctrl+alt+f";
      command = "forester.formatAllTrees";
      when = "editorTextFocus && resourceExtname == '.tree'";
    }
    # Structural inserts (see ./forester-edit). All leave the cursor between
    # the new braces. These shadow VS Code's Quick Open (ctrl+p), Trigger
    # Suggest (ctrl+i) and Toggle Developer Tools (ctrl+shift+i) in .tree
    # editors only.
    {
      key = "ctrl+i";
      command = "forestEdit.insertLi";
      when = "editorTextFocus && resourceExtname == '.tree'";
    }
    {
      key = "ctrl+shift+i";
      command = "forestEdit.insertLiOutermost";
      when = "editorTextFocus && resourceExtname == '.tree'";
    }
    {
      key = "ctrl+p";
      command = "forestEdit.appendP";
      when = "editorTextFocus && resourceExtname == '.tree'";
    }
    {
      key = "ctrl+#";
      command = "forestEdit.insertTag";
      when = "editorTextFocus && resourceExtname == '.tree'";
    }
  ];
}
