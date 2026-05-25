{
  config,
  pkgs,
  inputs,
  ...
}:

# let
#   thenixuser = import /home/cathe/dots/user.nix { };
#   # thehyprland = import (thenixuser.home + "/dots/nixos/programs/hyprland.nix") { };
# in
{
  imports = [
    ./git.nix
    ./shell
    ./firefox
    ./hyprland
  ];
}
