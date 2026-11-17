# The DMS "Repositories" bar menu (plugins/dotsRepos): every git repository
# under dots.repos.root, with its branch, how far it is ahead of and behind its
# upstream, its changed paths, its unmerged branches and its worktrees. Nothing
# runs while the popout is closed: opening it runs `repos --json` once
# (modules/home/repos). A repository's row opens to its branches and worktrees
# and the actions: fetch, open the directory, a terminal there, VS Code there,
# delete a merged branch, remove a clean worktree. The commands come from here,
# so the QML never guesses a path.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dots.repos;
  repos = "${cfg.package}/bin/repos";
  vscode = config.programs.vscode;

  # A program the menu starts is a child of dms.service, and stopping that
  # service (any rebuild that changes the DMS plugins or settings restarts it)
  # kills its whole cgroup, so a terminal or an editor started from here would
  # die with the next rebuild, work in it included (a VS Code that was already
  # running is only handed the folder, but a new one is a child too). A
  # transient scope of its own keeps it alive; DMS wraps its own commands the
  # same way (SessionService).
  detached = ["systemd-run" "--user" "--scope" "--collect" "--quiet"];
in {
  # The options the menu reads, so this file also works imported on its own
  # (modules dedupe by path).
  imports = [../repos];

  config = lib.mkIf cfg.enable {
    programs.dank-material-shell.plugins.dotsRepos = {
      enable = true;
      src = ./plugins/dotsRepos;
      settings = {
        root = cfg.root;
        # Each is an argv the menu appends to: nothing, repository IDs, "ID
        # NAME", "ID DIR", or a directory.
        statusCommand = [repos "--json"];
        fetchCommand = [repos "fetch"];
        branchDeleteCommand = [repos "branch-delete"];
        worktreeRemoveCommand = [repos "worktree-remove"];
        branchPublishCommand = [repos "branch-publish"];
        branchPushCommand = [repos "branch-push"];
        branchPullCommand = [repos "branch-pull"];
        branchSwitchCommand = [repos "branch-switch"];
        terminalCommand = detached ++ ["${config.programs.kitty.package}/bin/kitty" "--detach" "--directory"];
        openCommand = ["${pkgs.xdg-utils}/bin/xdg-open"];
        # The editor the vscode module builds (the --no-sandbox wrapper), when
        # there is one: without it the menu has no VS Code button.
        codeCommand = lib.optionals (vscode.enable && vscode.package != null) (detached ++ ["${vscode.package}/bin/code"]);
      };
    };
  };
}
