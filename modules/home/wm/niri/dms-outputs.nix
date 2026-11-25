# niri-dms-outputs, built from dms-outputs.sh (which says what it is for). Its own
# file so that checks/niri-dms-outputs.nix builds exactly the script the module
# installs, with a stand-in `niri` (the one thing it talks to).
#
# `niri` is the compositor's own package in the module, so the `niri msg` client
# and the running compositor are the same version (as for niri-move-column).
{
  pkgs,
  niri,
}:
pkgs.writeShellApplication {
  name = "niri-dms-outputs";
  runtimeInputs = [niri pkgs.jq pkgs.gawk pkgs.coreutils];
  text = builtins.readFile ./dms-outputs.sh;
}
