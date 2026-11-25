# flameshot-screen's behaviour (modules/home/flameshot/screen.sh), built the way the
# module builds it but with stand-ins for niri, wayland-info and flameshot that serve
# canned answers and record what Flameshot was asked to open. A real build and run,
# but no compositor, screen or Flameshot is touched: see flameshot-screen-test.sh for
# the cases.
{inputs}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  stub = name: pkgs.writeShellScriptBin name (builtins.readFile ./flameshot-screen-stubs.sh);
  script = import ../modules/home/flameshot/screen.nix {
    inherit pkgs;
    niri = stub "niri";
    flameshot = stub "flameshot";
    waylandInfo = stub "wayland-info";
  };
in {
  flameshot-screen = pkgs.runCommand "flameshot-screen-behaviour" {nativeBuildInputs = [script];} ''
    cp ${./flameshot-screen-test.sh} test.sh
    cp ${./flameshot-screen-wayland-info.txt} flameshot-screen-wayland-info.txt
    bash test.sh
    touch $out
  '';
}
