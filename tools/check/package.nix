# check (see check.sh): `nix run github:thecathe/dots#check` in a flake that
# consumes dots. It uses the nix already on PATH (the one that talks to the
# daemon), so nix is not among its inputs.
{pkgs}:
pkgs.writeShellApplication {
  name = "check";
  runtimeInputs = [
    pkgs.gawk
    (import ../../modules/home/rebuild/snapshot-package.nix {inherit pkgs;})
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
  ];
  text = builtins.readFile ./check.sh;
}
