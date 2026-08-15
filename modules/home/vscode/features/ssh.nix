{ pkgs, ... }:
{
  extensions =
    with pkgs.vscode-extensions;
    [
      ms-vscode.remote-explorer
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
    ]
    ++ (with pkgs.nix-vscode-extensions.vscode-marketplace-release-universal; [ ]);
  settings = {

  };
}
