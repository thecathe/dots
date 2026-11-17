# orient's behaviour against real git repositories (a stand-in for GitHub made
# of bare repositories, a devlog with a registry, a second host), and the merge
# that puts its hook and its one permission into Claude Code's settings. It
# builds the same script the module installs. A real build, not an evaluation,
# but it only runs git on a few tiny repositories.
{inputs}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  orient = import ../modules/home/devlog/orient-package.nix {inherit pkgs;};
in {
  orient = pkgs.runCommand "orient-behaviour" {nativeBuildInputs = [orient pkgs.git pkgs.jq];} ''
    bash ${./orient-test.sh}
    touch $out
  '';

  orient-settings-merge = pkgs.runCommand "orient-settings-merge" {nativeBuildInputs = [pkgs.jq];} ''
    MERGE_JQ=${../modules/home/devlog/merge-hooks.jq} bash ${./orient-merge-test.sh}
    touch $out
  '';
}
