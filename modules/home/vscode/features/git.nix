{ pkgs, ... }:
{
  extensions = [ ];
  settings = {

    "git" = {
      "openRepositoryInParentFolders" = "never";
      "enableSmartCommit" = true;
      "confirmSync" = false;
      "autofetch" = true;
    };

    "gitHistory.showEditorTitleMenuBarIcons" = false;

    "diffEditor" = {
      "ignoreTrimWhitespace" = false;
      "maxComputationTime" = 0;
      "useInlineViewWhenSpaceIsLimited" = false;
    };

    "scm" = {
      "repositories.sortOrder" = "path";
      "alwaysShowRepositories" = true;
      "inputFontFamily" = "JetBrainsMono Nerd Font Mono";
      "inputFontSize" = 14.857142857142858;
    };

  };
}
