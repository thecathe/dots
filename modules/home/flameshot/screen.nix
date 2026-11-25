# flameshot-screen, built from screen.sh (which says what it is for). Its own file so
# that checks/flameshot-screen.nix builds exactly the script the module installs,
# with stand-ins for the three programs it talks to.
#
# `niri` is the compositor's own package in the module, so the `niri msg` client
# and the running compositor are the same version; `flameshot` is the package the
# module runs (the patched one with `boundingBoxCrop`); `waylandInfo` is whatever
# provides a `wayland-info` command.
{
  pkgs,
  niri,
  flameshot,
  waylandInfo ? pkgs.wayland-utils,
}:
pkgs.writeShellApplication {
  name = "flameshot-screen";
  runtimeInputs = [niri pkgs.jq pkgs.gawk waylandInfo flameshot];
  text = builtins.readFile ./screen.sh;
}
