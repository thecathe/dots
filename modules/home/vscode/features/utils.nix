{ pkgs, ... }:
{
  extensions =
    with pkgs.vscode-extensions;
    [
      mkhl.direnv
      natqe.reload
      christian-kohler.path-intellisense
      # tomoki1207.pdf # conflicts with latex-workshop's own PDF handling
      # (workbench.editorAssociations -> latex-workshop-pdf-hook); commented
      # out repo-wide, temporarily, until upstream fixes per-profile extension
      # enablement (see default.nix) and this can be scoped out of just the
      # latex-containing profiles
      # redhat.vscode-yaml
    ]
    ++ (with pkgs.nix-vscode-extensions.vscode-marketplace-release-universal; [
      wraith13.zoombar-vscode
      amos402.scope-bar
      tomoki1207.selectline-statusbar
      sirtori.indenticator
      mattboston.status-bar-cursor-position
    ]);
  settings = {
    # "redhat.telemetry.enabled" = false;
    "wordcounter" = {
      "simple_wordcount" = false;
      "wordcounter.include_eol_chars" = false;
      "wordcounter.side.left" = [ "word" ];
    };
  };
}
