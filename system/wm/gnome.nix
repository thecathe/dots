{ pkgs, ... }:
{
  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  services.gnome.core-apps.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    gnome-weather
    gnome-maps
    gnome-connections
    gnome-contacts
    gnome-logs
    gnome-text-editor
    gnome-music # # never works
    gnome-photos
    gnome-tour
    gnome-user-docs
    showtime
    epiphany
    geary
  ];
  environment.systemPackages =
    with pkgs;
    with gnomeExtensions;
    [
      # blur-my-shell ## breaks with folders
      # just-perfection ## does nothing?
      # arc-menu
      # dynamic-panel ## does nothing?
      # dynamic-music-pill # # does nothing?
    ];
  # programs.geary.enable = false;
  # programs.epiphany.enable = false;
}
