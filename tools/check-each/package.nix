# check-each (see check-each.sh): `nix run github:thecathe/dots#check-each`, or from a
# checkout `nix run .#check-each`. It uses the nix and systemd-run already on PATH (the
# nix that talks to the daemon, the user's systemd that applies the memory ceiling), so
# neither is among its inputs; checks/check-each.nix builds it with stand-ins for both.
{pkgs}:
pkgs.writeShellApplication {
  name = "check-each";
  runtimeInputs = [
    pkgs.jq
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
  ];
  text = builtins.readFile ./check-each.sh;
}
