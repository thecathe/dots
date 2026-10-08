{pkgs, ...}: let
  # Pinned to an explicit marketplace version+hash, rather than
  # pkgs.nix-vscode-extensions...lucasaschenbach.unicode-math-symbols, which
  # always resolves to whatever version happens to be cached in that flake
  # input's daily-refreshed snapshot. The patch below targets an exact string
  # literal inside this version's package.json; an unpinned reference could
  # silently pick up a newer build on a future `nix flake update` whose
  # package.json layout no longer matches that literal, breaking the patch
  # without any obvious error. Bump the version/hash here deliberately when
  # actually upgrading, so that's a conscious, re-verified step.
  #
  # Upstream hardcodes its `contributes.snippets` language list in
  # package.json to ~19 mainstream language ids (plaintext, markdown,
  # python, js/ts, c/cpp/csharp, java, go, rust, kotlin, scala, swift, dart,
  # ruby, php, r, matlab) - VS Code only offers extension-contributed
  # snippets when the active editor's language id is on that list, so
  # without this patch the snippets never fire in forester (`.tree`),
  # rocq (`.v`), ocaml (`.ml`), or haskell (`.hs`) files. Append those
  # language ids, reusing the extension's existing snippets file.
  unicodeMathSymbols =
    (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        publisher = "LucasAschenbach";
        name = "unicode-math-symbols";
        version = "0.1.6";
        hash = "sha256-+8ky/5uoY3zRsWUoHM+jCje3lDgi9C5KJh/585IiMXY=";
      };
    }).overrideAttrs
    (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace package.json \
            --replace-fail \
            '{ "language": "matlab", "path": "./snippets/snippets.code-snippets" }' \
            '{ "language": "matlab", "path": "./snippets/snippets.code-snippets" }, { "language": "forester", "path": "./snippets/snippets.code-snippets" }, { "language": "rocq", "path": "./snippets/snippets.code-snippets" }, { "language": "ocaml", "path": "./snippets/snippets.code-snippets" }, { "language": "haskell", "path": "./snippets/snippets.code-snippets" }'
        '';
    });
in {
  extensions = [unicodeMathSymbols];
  settings = {
    "editor.quickSuggestions" = {
      "other" = true;
      "comments" = true;
      "strings" = true;
    };
    "editor.suggest.snippetsPreventQuickSuggestions" = false;
    "editor.snippetSuggestions" = "top";
  };
}
