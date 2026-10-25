{
  lib,
  pkgs,
  ...
}: let
  claudeDefaults = builtins.toJSON {
    includeCoAuthoredBy = true; # why lie?
    effortLevel = "xhigh";
    model = "opus";
    permissions = {
      defaultMode = "plan";
      disableBypassPermissionsMode = "disable";
    };
  };
in {
  # ~/.claude/settings.json must be a *single* symlink straight to the mutable
  # local file. home.file (even via mkOutOfStoreSymlink) routes it through the
  # read-only /nix/store/...-home-manager-files, and Claude Code saves settings
  # via a temp file next to the first symlink it resolves, which fails there
  # (EROFS) and breaks /effort, /model, etc. So link it by hand, after
  # home-manager's own link generation.
  home.activation.claudeCodeSettings = lib.hm.dag.entryAfter ["linkGeneration"] ''
    target="$HOME/dots/modules/home/claude/settings.local.json"
    link="$HOME/.claude/settings.json"
    if [ ! -e "$target" ]; then
      run install -Dm644 ${pkgs.writeText "claude-settings-default.json" claudeDefaults} "$target"
    fi
    if [ ! -e "$link" ] || [ -L "$link" ]; then
      run mkdir -p "$HOME/.claude"
      run ln -sfn "$target" "$link"
    else
      warnEcho "$link is a regular file; not replacing it with a symlink to $target"
    fi
  '';
  programs.claude-code = {
    enable = true;
    # settings.json stays a locally mutable file (see the activation step above),
    # so `settings` must remain unset here or home-manager will claim that path.
    # Global instructions are declarative and synced across hosts via git.
    context = ./global-instructions.md;
  };

  # Long-lived login for Claude Code (`claude setup-token`), read from a
  # per-host file so the secret never enters this repo or the nix store (the
  # store is world-readable; this repo is public). The file is created by hand
  # on each host that wants it, and skipped silently where it is absent:
  #
  #   mkdir -p -m 700 ~/.config/claude
  #   (umask 077; read -rs "t?token: " && print -rn -- "$t" > ~/.config/claude/oauth-token); unset t
  #
  # Paste the token as one line with no whitespace: `read` stops at the first
  # newline, and a stray control character makes the token invalid (401).
  # It outranks the `/login` credentials, so claude.ai connectors and Remote
  # Control are unavailable in a claude started this way. It expires after a
  # year: generate a new one and overwrite the file.
  #
  # Only `claude` itself gets it: a function sets CLAUDE_CODE_OAUTH_TOKEN for
  # that one command, rather than exporting it into the shell, where every
  # program the shell starts (dev shells, build scripts) would inherit it.
  programs.zsh.initContent = lib.mkOrder 600 ''
    claude() {
      local token_file="''${XDG_CONFIG_HOME:-$HOME/.config}/claude/oauth-token"
      if [[ -r $token_file ]]; then
        CLAUDE_CODE_OAUTH_TOKEN="$(<$token_file)" command claude "$@"
      else
        command claude "$@"
      fi
    }
  '';
}
