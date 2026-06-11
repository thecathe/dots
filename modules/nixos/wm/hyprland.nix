{ pkgs, ... }:

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
    enable = true;
    # withUWSM = withUWSM;
    xwayland.enable = true;
    # TODO:
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

}
