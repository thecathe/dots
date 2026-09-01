{...}: {
  # worklaptop's laptop-panel ("eDP-1") position for the dank desktop widgets,
  # kept host-scoped so it doesn't mix with the NixOS desktop's monitor data
  # in the shared modules/home/dank/settings.json - see modules/home/dank/dms.nix.
  dank.settingsOverlay = builtins.fromJSON (builtins.readFile ./dank-monitor.json);
}
