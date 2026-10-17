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
}
