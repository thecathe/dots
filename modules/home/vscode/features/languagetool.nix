{ pkgs, ... }:
{
  # pinned to valentjn.vscode-ltex (frozen at 13.1.0, last release before the
  # repo was archived) rather than the actively-maintained ltex-plus.vscode-ltex-plus
  # fork, because forester's forest-keeper extension only recognizes LTeX by this
  # exact extension ID: it hardcodes `getExtension("valentjn.vscode-ltex")` to find
  # and force-activate it (bypassing activationEvents entirely), which is also the
  # only reason grammar checking activates at all in a workspace of pure .tree files
  # -- ltex-plus's own activationEvents list has no `onLanguage:forester` entry, so
  # it never loads on its own in such a workspace.
  extensions = [ pkgs.vscode-extensions.valentjn.vscode-ltex ];
  settings = {
    "ltex.enabled" = [
      "bibtex"
      "context"
      "context.tex"
      "html"
      "latex"
      "markdown"
      "org"
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
