{pkgs, ...}: {
  extensions = [
    pkgs.nix-vscode-extensions.vscode-marketplace-release-universal.kdl-org.kdl
  ];
  settings = {
  };
}
