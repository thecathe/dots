{...}: {
  # AOC 24G4XED/39 (180Hz, connected via DisplayPort as "DP-1" on this host).
  # Host-specific so this doesn't get applied to other hosts' outputs, which
  # may also happen to be named "DP-1" but aren't this monitor.
  #
  # VRR is on-demand rather than always-on: always-on VRR caused visible
  # flicker on desktop apps. On-demand only enables VRR while a window
  # matching a `variable-refresh-rate` window-rule (e.g. the Hearthstone
  # Xwayland session in modules/home/wm/niri/config.kdl) is shown.
  wayland.windowManager.niri.extraConfig = ''
    output "DP-1" {
        mode "1920x1080@180.003"
        variable-refresh-rate on-demand=true
    }
  '';
}
