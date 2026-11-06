{pkgs, ...}: {
  extensions = with pkgs.vscode-extensions; [
    anthropic.claude-code
  ];
  settings = {
    "claudeCode.initialPermissionMode" = "plan";
    # `code` is wrapped to export CLAUDE_CODE_OAUTH_TOKEN (see ../default.nix)
    # so the extension counts as signed in. null removes it from integrated
    # terminals and their dev shells and build scripts; `claude` there gets it
    # from the zsh function in ../../claude.
    "terminal.integrated.env.linux".CLAUDE_CODE_OAUTH_TOKEN = null;
  };
}
