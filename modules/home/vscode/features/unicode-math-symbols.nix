{pkgs, ...}: {
  extensions = with pkgs.nix-vscode-extensions.vscode-marketplace-release-universal; [
    lucasaschenbach.unicode-math-symbols
  ];
  settings = {
  };
}
