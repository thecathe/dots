# dots.repos: every git repository under one directory at a glance. The `repos`
# CLI (repos.sh) prints a table or JSON of each repository's branch, how far it
# is ahead of and behind its upstream, its changed paths, its local branches
# (merged into the integration branch or not) and its worktrees, and does the
# few safe things a menu wants: fetch, delete a merged branch, remove a clean
# worktree. The DMS bar widget that shows the same, with actions, is
# modules/home/dank/repos-menu.nix (plugins/dotsRepos); it reads the CLI's JSON.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dots.repos;
in {
  options.dots.repos = {
    enable = lib.mkEnableOption "the repos CLI and, with DMS, the repositories bar menu";

    root = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Documents/git";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/Documents/git"'';
      description = "The directory holding the repositories, laid out as `<root>/<owner>/<name>`.";
    };

    integrationBranch = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {"thecathe/ocaml-forester" = "redirect-meta";};
      description = ''
        The branch finished work is merged into, per repository (`<owner>/<name>`),
        for repositories where it is not `main` (or `master`). Branches are
        reported as merged or not against it.
      '';
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["facebook/infer"];
      description = "Repositories (`<owner>/<name>`) to leave out, e.g. a huge checkout that is slow to status.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = import ./package.nix {
        inherit pkgs;
        inherit (cfg) root exclude;
        integration = cfg.integrationBranch;
      };
      defaultText = lib.literalMD "the `repos` CLI built from the options above";
      description = "The `repos` CLI; the DMS menu runs this one.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
  };
}
