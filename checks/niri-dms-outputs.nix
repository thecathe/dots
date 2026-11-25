# niri-dms-outputs' behaviour (modules/home/wm/niri/dms-outputs.sh), built the way the
# module builds it but with a stand-in `niri` that serves a canned
# `niri msg --json outputs` and records the `niri msg output NAME off` calls. A
# real build and run, but nothing touches a compositor: see niri-dms-outputs-test.sh
# for the cases.
{inputs}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  stubNiri = pkgs.writeShellScriptBin "niri" (builtins.readFile ./niri-dms-outputs-stub.sh);
  script = import ../modules/home/wm/niri/dms-outputs.nix {
    inherit pkgs;
    niri = stubNiri;
  };
in {
  niri-dms-outputs = pkgs.runCommand "niri-dms-outputs-behaviour" {nativeBuildInputs = [script pkgs.jq];} ''
    bash ${./niri-dms-outputs-test.sh}
    touch $out
  '';
}
