{ pkgs, ... }:
{
  extensions =
    with pkgs.vscode-extensions;
    [
      mkhl.direnv
      natqe.reload
      christian-kohler.path-intellisense
      tomoki1207.pdf
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
