{pkgs, ...}: {
  extensions = with pkgs.vscode-extensions; [
    anthropic.claude-code
  ];
  settings = {
    "claudeCode.initialPermissionMode" = "plan";
  };
}
