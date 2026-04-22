{ pkgs, ... }:
{
  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
  ];
  services.gnome.core-apps.enable = false;
  environment.systemPackages =
    with pkgs;
    with gnomeExtensions;
    [
      tracker3
      blur-my-shell
      just-perfection
      # arc-menu
      dynamic-panel
      dynamic-music-pill
    ];
  programs.geary.enable = false;
}
