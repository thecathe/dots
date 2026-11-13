# dlsync's behaviour against real git repositories (a bare origin and two clones
# standing in for the two hosts): fast-forward, merge, conflict, dirty tree,
# push failure and the rest. It builds the same script the module installs. A
# real build, not an evaluation, but it only runs git on a few tiny repos.
{inputs}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  dlsync = import ../modules/home/devlog/package.nix {inherit pkgs;};
in {
  dlsync = pkgs.runCommand "dlsync-behaviour" {nativeBuildInputs = [dlsync pkgs.git pkgs.util-linux];} ''
    bash ${./dlsync-test.sh}
    touch $out
  '';
}
