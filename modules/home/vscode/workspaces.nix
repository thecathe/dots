# Pinned VSCode workspaces: the `code-workspace` tool (see code-workspace.sh).
# It opens a workspace in its profile, offers to clone missing repos, and
# generates a launcher entry per workspace.
#
# This module holds only the mechanism. The workspace files and manifest live
# in a separate private repo (checked out at ~/workspaces, see
# programs.vscode.workspaces.dir) and are read at runtime, never at evaluation,
# so this evaluates the same whether or not that repo exists. With `dir` null
# the module does nothing.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.vscode.workspaces;

  codeWorkspace = pkgs.writeShellApplication {
    name = "code-workspace";
    runtimeInputs = with pkgs; [coreutils findutils gawk gnugrep gnused git jq fuzzel libnotify];
    runtimeEnv.CODE_WORKSPACE_DIR = cfg.dir;
    text = builtins.readFile ./code-workspace.sh;
  };
in {
  options.programs.vscode.workspaces.dir = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "/home/me/workspaces/vscode";
    description = ''
      Directory of *.code-workspace files plus a manifest.json (profiles, repos,
      untracked). Folder paths inside the workspace files are relative to this
      directory. Null disables the feature.
    '';
  };

  config = lib.mkIf (cfg.dir != null) {
    home.packages = [codeWorkspace];

    # Regenerates launcher entries from whatever is in `dir` (no-op if absent).
    home.activation.codeWorkspaceEntries = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${codeWorkspace}/bin/code-workspace --sync-entries
    '';
  };
}
