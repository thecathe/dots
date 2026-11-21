# The user's home-manager configuration on a machine that does not run NixOS
# (standalone home-manager on another distribution).
{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.dots.homeModules.default];

  home.username = "NEW_USER";
  home.homeDirectory = "/home/NEW_USER";

  # Several of dots' modules and scripts read and write files in a checkout of dots,
  # expected at ~/dots; set dots.checkout if it lives elsewhere.
  home.sessionPath = ["${config.dots.checkout}/bin"];

  # Standalone home-manager installs and updates itself.
  programs.home-manager.enable = true;

  # Fits home-manager's programs into a non-NixOS system: XDG data dirs,
  # fonts, the session environment.
  targets.genericLinux.enable = true;

  # The nix that home-manager manages, with flakes on.
  nix = {
    package = pkgs.nix;
    settings.experimental-features = ["nix-command" "flakes"];
  };

  # The home-manager release this config was first written for. Leave it as it
  # is; read the home-manager release notes before ever changing it.
  home.stateVersion = "26.05";
}
