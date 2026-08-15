{ pkgs, ... }:
{
  extensions = [ pkgs.vscode-extensions.ltex-plus.vscode-ltex-plus ];
  settings = {
    #### below was for older ltex extension -- likely unrelated
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
