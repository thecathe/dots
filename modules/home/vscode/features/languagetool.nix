{ pkgs, ... }:
{
  # ltex-plus.vscode-ltex-plus is the actively-maintained fork of the now-archived
  # valentjn.vscode-ltex. forester's forest-keeper extension hardcodes a check for
  # the old extension ID to find-and-force-activate LTeX (see the overrideAttrs
  # patch on forest-keeper in modules/home/vscode/features/forester.nix, which
  # retargets that check at this extension's ID instead).
  extensions = [ pkgs.vscode-extensions.ltex-plus.vscode-ltex-plus ];
  settings = {
    "ltex.enabled" = [
      "bibtex"
      "context"
      "context.tex"
      "html"
      "latex"
      "markdown"
      "mdx"
      "typst"
      "asciidoc"
      "neorg"
      "org"
      "quarto"
      "restructuredtext"
      "rsweave"
      "forester"
    ];

    # "ltex" = {
    #                   "disabledRules" = {
    #                     "en-GB" = [ "SENTENCE_WHITESPACE" ];
    #                   };
    #                   "enabledRules" = { };
    #                   "additionalRules.motherTongue" = "en-GB";
    #                   "language" = "en-GB";
    #                   "completionEnabled" = true;
    #                 };
  };
}
