# The user's home-manager configuration on this machine.
{inputs, ...}: {
  imports = [inputs.dots.homeModules.default];

  home.username = "NEW_USER";
  home.homeDirectory = "/home/NEW_USER";

  # dots' scripts, and several of its modules, expect the dots checkout (or a
  # link to it) at ~/dots.
  home.sessionPath = ["$HOME/dots/bin"];

  # The home-manager release this config was first written for. Leave it as it
  # is; read the home-manager release notes before ever changing it.
  home.stateVersion = "26.05";
}
