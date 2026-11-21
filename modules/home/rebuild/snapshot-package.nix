# dots-snapshot (see dots-snapshot.sh), as its own file so the rebuild module and
# the `check` tool (tools/check) run the very same script.
{pkgs}:
pkgs.writeShellApplication {
  name = "dots-snapshot";
  runtimeInputs = [pkgs.git pkgs.coreutils];
  text = builtins.readFile ./dots-snapshot.sh;
}
