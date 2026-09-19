{
  pkgs,
  ...
}: {
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  # NixOS otherwise injects a stripped PATH via Environment= on the niri.service
  # unit which shadows the imported user-manager PATH. Disabling the default
  # lets niri inherit the full PATH set up by niri-session.
  systemd.user.services.niri.enableDefaultPath = false;

  # IME not working on Electron apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # niri auto-spawns xwayland-satellite on demand (since 25.08) as long as the
  # binary is on PATH - it still needs to be installed, just no manual
  # spawn-at-startup/DISPLAY wiring. Note: X11 apps that position themselves at
  # absolute screen coordinates (e.g. game overlays) still won't behave
  # correctly under this rootless proxy - that needs a nested compositor.
  environment.systemPackages = with pkgs; [
    xwayland-satellite # xwayland support
  ];

  # File picker not working
  xdg.portal.config.niri = {
    "org.freedesktop.impl.portal.FileChooser" = ["gtk"]; # or "kde"
  };
}
