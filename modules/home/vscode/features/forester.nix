{pkgs, ...}: {
  extensions = with pkgs.vscode-extensions; [
    pkgs.nix-vscode-extensions.vscode-marketplace-release-universal.kaierikniermann.forest-keeper
  ];
  settings = {
    "claudeCode.initialPermissionMode" = "plan";
  };
}
