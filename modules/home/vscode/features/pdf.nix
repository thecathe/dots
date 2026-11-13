{pkgs, ...}: {
  # A PDF viewer for every profile without LaTeX Workshop. That has its own
  # (workbench.editorAssociations -> latex-workshop-pdf-hook) and the two
  # clash. groups.nix adds this feature to exactly those profiles: don't list
  # it in a group.
  extensions = with pkgs.vscode-extensions; [
    tomoki1207.pdf
  ];
  settings = {};
}
