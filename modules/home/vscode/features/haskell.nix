{pkgs, ...}: {
  extensions = with pkgs.vscode-extensions; [
    haskell.haskell
    justusadam.language-haskell
  ];
  settings = {
  };
}
