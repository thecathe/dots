# repos' behaviour against real git repositories under a throwaway root:
# discovery, every reported field, the refusals (unmerged branch, dirty
# worktree), fetch from a bare origin, the config file. It builds the same
# script the module installs. A real build, not an evaluation, but it only runs
# git on a few tiny repositories.
{inputs}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  repos = import ../modules/home/repos/package.nix {inherit pkgs;};
in {
  repos = pkgs.runCommand "repos-behaviour" {nativeBuildInputs = [repos pkgs.git pkgs.jq];} ''
    bash ${./repos-test.sh}
    touch $out
  '';
}
