{
  config,
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
  home.activation.claudeCodeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/dots/modules/home/claude/settings.local.json"
    if [ ! -e "$target" ]; then
      install -Dm644 ${pkgs.writeText "claude-settings-default.json" claudeDefaults} "$target"
    fi
  '';
  home.file.".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dots/modules/home/claude/settings.local.json";
  programs.claude-code = {
    enable = true;
    # settings can now be locally overridden
  };
}
