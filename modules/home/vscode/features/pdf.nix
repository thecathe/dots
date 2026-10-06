{pkgs, ...}: {
  extensions = with pkgs.vscode-extensions; [
    tomoki1207.pdf # conflicts with latex-workshop's own PDF handling
    # (workbench.editorAssociations -> latex-workshop-pdf-hook); commented
    # out repo-wide, temporarily, until upstream fixes per-profile extension
    # enablement (see default.nix) and this can be scoped out of just the
    # latex-containing profiles
  ];
  settings = {};
}
