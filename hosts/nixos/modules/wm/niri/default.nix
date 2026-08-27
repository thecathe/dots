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

  # XWayland apps not working
  environment.systemPackages = with pkgs; [
    xwayland-satellite # xwayland support
  ];

  # File picker not working
  xdg.portal.config.niri = {
    "org.freedesktop.impl.portal.FileChooser" = ["gtk"]; # or "kde"
  };
}
