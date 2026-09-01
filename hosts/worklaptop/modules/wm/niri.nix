{
  pkgs,
  inputs,
  lib,
  ...
}: let
  nixgl = inputs.nixgl;
  nixGLPrefix = "${nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel}/bin/nixGLIntel";
in {
  # The wayland-session Exec= target (templates/wayland-sessions/niri.desktop).
  # Two things a bare `exec niri` misses on a non-NixOS login:
  #  - GDM doesn't source a login shell for a custom Exec=, so PATH/XDG_DATA_DIRS
  #    never get home-manager's hm-session-vars.sh treatment. Without it, PATH
  #    falls back to distro defaults where /usr/bin/firefox (the apt/snap
  #    wrapper, its own separate profile) shadows ~/.nix-profile/bin/firefox
  #    (the home-manager-managed one with the user's actual profile).
  #  - Launching niri directly (instead of niri-session) skips niri-session's
  #    `systemctl --user import-environment` / `dbus-update-activation-environment`
  #    step, so systemd user services gated on graphical-session.target (dank
  #    material shell, mako, swayidle, polkit-gnome) start with a stale/empty
  #    environment (no WAYLAND_DISPLAY) instead of niri's actual one.
  # Sourcing hm-session-vars.sh first, then wrapping niri-session (not niri
  # directly) with nixGL fixes both: niri-session's import-environment then
  # carries the corrected PATH *and* nixGL's GL env vars into systemd --user,
  # so niri.service - whose ExecStart still points at the real, unwrapped
  # pkgs.niri path baked in at package build time - inherits them too.
  home.packages = [
    (pkgs.writeShellScriptBin "niri-nixgl" ''
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      exec ${nixGLPrefix} "$HOME/.nix-profile/bin/niri-session" "$@"
    '')
  ];

  # niri's own bundled portal config (share/xdg-desktop-portal/niri-portals.conf
  # in pkgs.niri) only sets a "default=gnome;gtk;" fallback, which leaves
  # FileChooser going to gnome and not working correctly - same bug the NixOS
  # host hit (hosts/nixos/modules/wm/niri/default.nix). This file lives under
  # $XDG_CONFIG_HOME, which xdg-desktop-portal checks before any
  # package-provided config, so it overrides niri's bundled default here.
  xdg.configFile."xdg-desktop-portal/niri-portals.conf".text = ''
    [preferred]
    default=gnome
    org.freedesktop.impl.portal.FileChooser=gtk
  '';
}
