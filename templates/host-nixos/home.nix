# The user's home-manager configuration on this machine.
{
  config,
  inputs,
  ...
}: {
  imports = [inputs.dots.homeModules.default];

  home.username = "NEW_USER";
  home.homeDirectory = "/home/NEW_USER";

  # Several of dots' modules and scripts read and write files in a checkout of dots,
  # expected at ~/dots; set dots.checkout if it lives elsewhere.
  home.sessionPath = ["${config.dots.checkout}/bin"];

  # The home-manager release this config was first written for. Leave it as it
  # is; read the home-manager release notes before ever changing it.
  home.stateVersion = "26.05";
}
