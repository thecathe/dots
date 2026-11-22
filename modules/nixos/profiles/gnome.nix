# The `gnome` profile: the GNOME desktop with GDM, its portals and a trimmed set of
# its core apps. A whole second desktop next to niri, so that a machine still has a
# working session when the window manager does not start. Its home-manager half
# (extensions, GTK theme) is the home `gnome` profile (modules/home/profiles).
#
# Not here: the default terminal (`xdg.terminal-exec`), which niri's session uses
# as well.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  options.dots.profile.gnome.enable = lib.mkEnableOption "the gnome profile: GNOME and GDM, the GNOME portals and its core apps less the ones this setup does not use";

  config = lib.mkIf config.dots.profile.gnome.enable {
    services.displayManager.gdm.enable = mkDefault true;
    services.desktopManager.gnome.enable = mkDefault true;

    qt.platformTheme = mkDefault "gnome";

    # Touchpad support (most desktop managers turn it on anyway).
    services.libinput.enable = mkDefault true;

    # Screen casting (still not for full-screen windows) and screenshots in a
    # GNOME session.
    xdg.portal = {
      enable = mkDefault true;
      extraPortals = [pkgs.xdg-desktop-portal-gnome];
      config.gnome = {
        default = ["gnome"];
        "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
        "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
        "org.freedesktop.impl.portal.RemoteDesktop" = ["gnome"];
      };
    };

    services.gnome.core-apps.enable = mkDefault true;
    environment.gnome.excludePackages = with pkgs; [
      gnome-weather
      gnome-maps
      gnome-connections
      gnome-contacts
      gnome-logs
      gnome-text-editor
      gnome-music # never worked with a library on another drive
      gnome-tour
      gnome-user-docs
      gnome-console
      gnome-characters
      gnome-tecla # keyboard viewer
      decibels # audio
      epiphany # browser
      showtime # videos
      geary # mail
      yelp # help
    ];

    services.udev.packages = [pkgs.gnome-settings-daemon];
  };
}
