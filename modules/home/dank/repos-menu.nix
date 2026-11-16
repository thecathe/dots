# The DMS "Repositories" bar menu (plugins/dotsRepos): every git repository
# under dots.repos.root, with its branch, how far it is ahead of and behind its
# upstream, its changed paths, its unmerged branches and its worktrees. Nothing
# runs while the popout is closed: opening it runs `repos --json` once
# (modules/home/repos). A repository's row opens to its branches and worktrees
# and the actions: fetch, open the directory, a terminal there, delete a merged
# branch, remove a clean worktree. The commands come from here, so the QML
# never guesses a path.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dots.repos;
  repos = "${cfg.package}/bin/repos";
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
        terminalCommand = ["${config.programs.kitty.package}/bin/kitty" "--detach" "--directory"];
        openCommand = ["${pkgs.xdg-utils}/bin/xdg-open"];
      };
    };
  };
}
