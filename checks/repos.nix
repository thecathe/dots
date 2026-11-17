# repos' behaviour against real git repositories under a throwaway root:
# discovery, every reported field, the refusals (unmerged branch, dirty
# worktree), fetch from a bare origin, the config file. It builds the same
# script the module installs. A real build, not an evaluation, but it only runs
# git on a few tiny repositories.
#
# repos-owners-option is the other half: that the `owners` filter travels from
# package.nix's argument, through its JSON file, to the CLI (the bash check
# drives the script with environment overrides and hand-written config files
# instead). The root is overridden, the owners are the baked ones.
{inputs}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  repos = import ../modules/home/repos/package.nix {inherit pkgs;};
  owned = import ../modules/home/repos/package.nix {
    inherit pkgs;
    owners = ["q"];
  };
in {
  repos = pkgs.runCommand "repos-behaviour" {nativeBuildInputs = [repos pkgs.git pkgs.jq];} ''
    bash ${./repos-test.sh}
    touch $out
  '';

  repos-owners-option = pkgs.runCommand "repos-owners-option" {nativeBuildInputs = [owned pkgs.git pkgs.jq];} ''
    export HOME=$TMPDIR
    mkdir -p g/o g/q
    git init -q g/o/a
    git init -q g/q/b
    got=$(REPOS_ROOT=$PWD/g repos --json | jq -r '.repos | map(.id) | join(",")')
    if [ "$got" != "q/b" ]; then
      echo "listed: $got" >&2
      echo "wanted: q/b (only the owner the package was built with)" >&2
      exit 1
    fi
    touch $out
  '';
}
