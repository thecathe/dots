{pkgs, ...}: {
  extensions = with pkgs.vscode-extensions;
    [
      ms-vscode.remote-explorer
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
    ]
    ++ (with pkgs.nix-vscode-extensions.vscode-marketplace-release-universal; []);
  settings = {
    # Installed on every host a remote window connects to, so Claude Code runs
    # there and sees that host's ~/.claude (conversations, CLAUDE.md, skills)
    # rather than showing an "Install in SSH" button.
    "remote.SSH.defaultExtensions" = ["anthropic.claude-code"];
    # Keep the connection's login terminal visible: a host that asks for a
    # browser sign-in first (Tailscale SSH's check mode) prints its link there,
    # and a hidden terminal just looks like a hang.
    "remote.SSH.showLoginTerminal" = true;
  };
}
