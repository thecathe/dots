{ pkgs, ... }:

let
  enabled = true;
  withUWSM = false;
in
{
  # https://mynixos.com/options/programs.hyprland
  # wayland.windowManager.hyprland = {
  #   enable = enabled;
  #   # Need to disable systemd integration if hyprland is enabled: https://wiki.nixos.org/wiki/Hyprland
  #   systemd.enable = !withUWSM;
  #   plugins =
  #     with pkgs;
  #     with hyperlandPlugins;
  #     [
  #       hy3
  #       hyprspace
  #       hyprsplit
  #       hyprfocus
  #       hyprbars
  #       hyprtrails
  #       hypr-dynamic-cursors
  #     ];
  # };
  programs.hyprland = {
    enable = enabled;
    withUWSM = withUWSM;
    xwayland.enable = enabled;
    # TODO:
  };
}
