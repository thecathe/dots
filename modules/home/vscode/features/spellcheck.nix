{pkgs, ...}: {
  # Lightweight spell checking (Code Spell Checker / cspell), as a cheaper
  # alternative to LTeX (./languagetool.nix) where full grammar checking
  # isn't worth its cost: LTeX runs LanguageTool in a separate JVM that sits
  # at ~1.1 GB RSS (~750 MB of it live English rule objects), whereas cspell
  # runs as a Node language server with word lists only.
  extensions = [pkgs.vscode-extensions.streetsidesoftware.code-spell-checker];
  settings = {
    # cspell's default ("*" = true) already covers forester; listed so it
    # stays enabled if that default ever narrows.
    "cSpell.enabledFileTypes" = {
      "forester" = true;
    };
    # cspell has no forester grammar, so skip markup it would otherwise flag:
    # macro names (\p, \transclude, ...) and inline/display math (#{...},
    # ##{...}, not nested-brace aware).
    "cSpell.languageSettings" = [
      {
        languageId = "forester";
        ignoreRegExpList = [
          "/\\\\[a-zA-Z]+/g"
          "/##?\\{[^}]*\\}/g"
        ];
      }
    ];
  };
}
