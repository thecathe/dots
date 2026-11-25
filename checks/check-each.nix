# check-each's behaviour (tools/check-each/check-each.sh), built the way the flake builds it
# but run against stand-ins for `nix` and `systemd-run` that serve canned answers and
# record what they were asked. A real build and run of the script, but nothing is
# evaluated, built or limited: see check-each-test.sh for the cases.
{inputs}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  script = import ../tools/check-each/package.nix {inherit pkgs;};
in {
  check-each = pkgs.runCommand "check-each-behaviour" {nativeBuildInputs = [script pkgs.jq pkgs.coreutils pkgs.gawk];} ''
    bash ${./check-each-test.sh}
    touch $out
  '';
}
